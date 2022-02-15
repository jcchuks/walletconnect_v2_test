import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:app/src/walletconnect/models/json_rpc_request.dart';
import 'package:app/src/walletconnect/models/pairing_participant.dart';
import 'package:app/src/walletconnect/models/pairing_permissions.dart';
import 'package:app/src/walletconnect/models/pairing_proposal.dart';
import 'package:app/src/walletconnect/models/pairing_settled.dart';
import 'package:app/src/walletconnect/models/pairing_success_response.dart';
import 'package:app/src/walletconnect/models/params.dart';
import 'package:app/src/walletconnect/models/session_participant.dart';
import 'package:app/src/walletconnect/models/session_permissions.dart';
import 'package:app/src/walletconnect/models/session_settled.dart';
import 'package:app/src/walletconnect/models/session_success_response.dart';
import 'package:app/src/walletconnect/wc_core.dart';
import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_events.dart';
import 'package:app/src/walletconnect/wc_state.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:cryptography/cryptography.dart';

class DeserializedData {
  final String cipher;
  final String nonce;
  final String mac;
  final String publicKey;

  DeserializedData(
      {required this.cipher,
      required this.nonce,
      required this.mac,
      required this.publicKey});
}

class Helpers {
  static void checkString(String? data, {String? msg}) {
    if (data?.isEmpty ?? true) {
      throw WcException(type: WcErrorType.emptyValue, msg: msg);
    }
  }

  static String getOutBandUri({required State state}) {
    String uri = Uri.encodeComponent(
        state.pairingSignal.pairingProposerParams!.uri ?? '');
    checkString(uri, msg: "getOutBandUri - uri empty");
    var rel = '{"protocol":"${state.uriParameters.relay!.protocol}"}';
    rel = Uri.encodeComponent(rel);
    var query =
        '/?&publicKey=${state.uriParameters.publicKey}&relay=$rel&controller=${state.uriParameters.controller}';

    uri =
        "wc:${state.uriParameters.topic}@${state.uriParameters.version}?bridge=$uri$query";

    log(uri);
    return uri;
  }

  static Future<List<SecretKey>> getEncryptionDecryptionKeys(
      {required String sharedKey}) async {
    List<int> sharedKeyBytes = hex.decode(sharedKey);
    Sha512 encAuthHash = Sha512();
    Hash encAuthKeys = await encAuthHash.hash(sharedKeyBytes);
    int partition = encAuthKeys.bytes.length ~/ 2;

    var encryptionKeys = encAuthKeys.bytes.getRange(0, partition).toList();
    var authenticationKeys = encAuthKeys.bytes
        .getRange(partition, encAuthKeys.bytes.length)
        .toList();

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    SecretKey encryptionSecretKey =
        await algorithm.newSecretKeyFromBytes(encryptionKeys);
    SecretKey authenticationSecretKey =
        await algorithm.newSecretKeyFromBytes(authenticationKeys);
    return [encryptionSecretKey, authenticationSecretKey];
  }

  static String getRelayUri({required State state}) {
    String uri =
        "${state.pairingSignal.pairingProposerParams!.uri ?? ''}&version=${state.uriParameters.version}";
    checkString(uri, msg: "getRelayUri - uri empty");
    uri = uri.replaceAll("https://", "wss://");
    return uri;
  }

  static Future<SecretKey> getSharedKey(
      {required KeyPair keyPair, required String responderPublicKey}) async {
    final algorithm = X25519();
    SimplePublicKey remotePublicKey = SimplePublicKey(
        hex.decode(responderPublicKey),
        type: KeyPairType.x25519);
    SecretKey sharedKey = await algorithm.sharedSecretKey(
        keyPair: keyPair, remotePublicKey: remotePublicKey);
    return sharedKey;
  }

  static Future<String> getTopicOnSettlement(
      {required SecretKey sharedKey}) async {
    return await getSha256(data: await sharedKey.extractBytes());
  }

  static Future<String> pairingSettlement(
      {required WcLibCore core,
      required PairingSuccessResponse pairingSuccessResponse}) async {
    State state = core.state;
    SecretKey sharedKey = await getSharedKey(
        keyPair: core.state.keyPair,
        responderPublicKey: pairingSuccessResponse.responder!.publicKey!);
    var topic = await getTopicOnSettlement(sharedKey: sharedKey);
    var publicKey = state.pairingProposal.pairingProposer!.publicKey;
    var self = PairingParticipant(publicKey: publicKey);

    var sharedKeyAsString = hex.encode(await sharedKey.extractBytes());
    core.state.pairingSettled = PairingSettled(
        topic: topic,
        relay: pairingSuccessResponse.relay,
        sharedKey: sharedKeyAsString,
        self: self,
        peer: pairingSuccessResponse.responder,
        permissions: PairingPermissions(
            controller: PairingPermissionsController(publicKey: publicKey),
            pairingProposedPermissions:
                state.pairingProposal.pairingProposedPermissions),
        expiry: pairingSuccessResponse.expiry,
        state: pairingSuccessResponse.state);
    Map<String, Map<SimpleKeyPair, PairingSettled>> other = {
      topic: {core.state.keyPair: core.state.pairingSettled}
    };
    core.state.settledPairingsMap.addAll(other);
    return topic;
  }

  static void sessionSettlement(
      {required WcLibCore core,
      required SessionSuccessResponse sessionSuccessResponse}) async {
    State state = core.state;
    var sharedKey = await getSharedKey(
        keyPair: core.state.keyPair,
        responderPublicKey:
            sessionSuccessResponse.sessionParticipant!.publicKey ?? '');
    var topic = await getTopicOnSettlement(sharedKey: sharedKey);
    var publicKey = state.pairingProposal.pairingProposer!.publicKey;
    var self = SessionParticipant(
        publicKey: publicKey,
        appMetadata: state.sessionProposal.proposer!.metadata);
    assert(sessionSuccessResponse.topic ==
        topic); //if fails, know sharedKey is invalid

    var sharedKeyAsString = hex.encode(await sharedKey.extractBytes());

    core.state.sessionSettled = SessionSettled(
      topic: sessionSuccessResponse.topic,
      relay: sessionSuccessResponse.relay,
      expiry: sessionSuccessResponse.expiry,
      peer: sessionSuccessResponse.sessionParticipant,
      self: self,
      sharedKey: sharedKeyAsString,
      sessionState: sessionSuccessResponse.sessionState,
      permissions: SessionPermissions(
          pairingPermissionsController:
              SessionPermissionsController(publicKey: publicKey),
          sessionProposedPermissions: state.sessionProposal.permissions),
    );
    log("Session Settled");
    // log(topic);
    // log(core.state.settledPairingsMap.keys.first);
    Map<String, Map<SimpleKeyPair, PairingSettled>> other = {
      topic: {core.state.keyPair: core.state.pairingSettled}
    };
    core.state.settledSessionsMap.addAll(other);
  }

  static void removeSettledSession({required WcLibCore core}) {
    core.state.sessionSettled = SessionSettled.emptySession();
  }

  static bool isFailedResponse(Map<String, dynamic>? resp) {
    return resp!.keys.contains("reason");
  }

  static bool isSubscriptionEvent(Map<String, dynamic> data) {
    return data.containsKey("method") && data.containsKey("params");
  }

  static bool isWcPairingApproveEvent(JsonRpcRequest req) {
    return req.method == Events.wcPairingApprove;
  }

  static isSubscribeEvent(Map<String, dynamic> event) {
    return event["result"].toString().length > 6;
  }

  static raiseExceptionOnEmotyOrInvalidJsonRpcRequestPayloadParams(
      {Params? params}) {
    if (params?.data?.isEmpty ?? true) {
      throw WcException(
          type: WcErrorType.invalidValue, msg: "Params is invalid or empty");
    }
  }

  static void removePairingProposal(WcLibCore core) {
    core.state.pairingProposal = PairingProposal(topic: '');
  }

  static int _addPadding(List<int> data, int offset) {
    var code = (data.length - offset);

    while (offset < data.length) {
      data[offset] = code;
      offset++;
    }

    return code;
  }

  static List<int> addPkcs7Padding({required String message}) {
    List<int> data = utf8.encode(message).toList();
    int msgLengthInBytes = data.length;
    //AES 256 has a block size of 32 bytes hence find remainder
    // pkcs5 whose block size is 8 is compatible with pkcs7 since 8 is a factor
    // of 256.
    const int blockSize = 8;
    int blockModulo = msgLengthInBytes % blockSize;
    int padRemainderBlockCount = blockSize - blockModulo;
    data.addAll(
        List.generate(padRemainderBlockCount, (index) => index).toList());

    Uint8List bytes = Uint8List.fromList(data);
    var paddingCount = PKCS7Padding().addPadding(bytes, msgLengthInBytes);
    log(paddingCount.toString() +
        " " +
        padRemainderBlockCount.toString() +
        " " +
        bytes.length.toString() +
        " " +
        msgLengthInBytes.toString());
    assert(paddingCount == padRemainderBlockCount);
    assert(bytes.length == msgLengthInBytes + padRemainderBlockCount);
    return bytes;
  }

  static Future<String> computeHmac(
      {required List<int> nonce,
      required List<int> publicKey,
      required List<int> cipherBytes,
      required SecretKey authenticationSecretKey}) async {
    Hmac mac = Hmac.sha256();
    List<int> payload = List.from(nonce)
      ..addAll(publicKey)
      ..addAll(cipherBytes);
    Mac messageMac =
        await mac.calculateMac(payload, secretKey: authenticationSecretKey);
    String macStr = hex.encode(messageMac.bytes);
    return macStr;
  }

  static Future<String> encrypt(
      {required String sharedKey,
      required String message,
      required String publicKey,
      String iv = ''}) async {
    List<SecretKey> keys =
        await Helpers.getEncryptionDecryptionKeys(sharedKey: sharedKey);
    SecretKey encryptionSecretKey = keys[0];
    SecretKey authenticationSecretKey = keys[1];

    var messageBytes =
        utf8.encode(message); //addPkcs7Padding(message: message);

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    List<int> nonce = iv.isEmpty ? algorithm.newNonce() : hex.decode(iv);

    final secret = await algorithm.encrypt(messageBytes,
        secretKey: encryptionSecretKey, nonce: nonce);

    String macStr = await computeHmac(
        nonce: nonce,
        publicKey: hex.decode(publicKey),
        cipherBytes: secret.cipherText,
        authenticationSecretKey: authenticationSecretKey);

    iv = hex.encode(nonce);
    String cipherTxt = hex.encode(secret.cipherText);

    var data = '$iv$publicKey$macStr$cipherTxt';

    return data;
  }

// @TODO - return 'msg' as custom type containing iv, pk, mac, cipher.
  static DeserializedData getDeserializedData({required String data}) {
    int nonceEnds = 32;
    int publicKeyEnds = 96;
    int macEnds = 160;

    String nonceStr = data.substring(0, nonceEnds);

    String publicKeyStr = data.substring(nonceEnds, publicKeyEnds);
    String macStr = data.substring(publicKeyEnds, macEnds);
    String cipherStr = data.substring(macEnds);
    return DeserializedData(
        nonce: nonceStr,
        publicKey: publicKeyStr,
        mac: macStr,
        cipher: cipherStr);
  }

// @TODO - replace 'message' with a custom type containing iv, pk, mac, cipher.
  static Future<String> decrypt(
      {required String sharedKey, required String message}) async {
    String nonce, publicKey, macStr, cipherText = '';

    List<SecretKey> keys =
        await Helpers.getEncryptionDecryptionKeys(sharedKey: sharedKey);
    SecretKey decryptionSecretKey = keys[0];
    SecretKey authenticationSecretKey = keys[1];

    DeserializedData deserializedData =
        Helpers.getDeserializedData(data: message);
    nonce = deserializedData.nonce;
    publicKey = deserializedData.publicKey;
    macStr = deserializedData.mac;
    cipherText = deserializedData.cipher;

    var cipherTextBytes = hex.decode(cipherText);
    log("public key: : " + publicKey);

    //------------ verify mac
    String computedMac = await computeHmac(
        nonce: hex.decode(nonce),
        publicKey: hex.decode(publicKey),
        cipherBytes: cipherTextBytes,
        authenticationSecretKey: authenticationSecretKey);

    if (computedMac != macStr) {
      throw WcException(
          type: WcErrorType.invalidValue,
          msg:
              "got mac string as $computedMac, received '$macStr' with invalid mac");
    }

    //---------- decrypt cipherText
    SecretBox secretBox =
        SecretBox(cipherTextBytes, nonce: hex.decode(nonce), mac: Mac.empty);

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    final messageBytes =
        await algorithm.decrypt(secretBox, secretKey: decryptionSecretKey);
    final decodedPayload = utf8.decode(messageBytes);

    //log(cipherTextBytes.length.toString());

    return decodedPayload;
  }

  static Future<String> getSha256({required List<int> data}) async {
    final hashAlgorithm = Sha256();
    Hash topicHash = await hashAlgorithm.hash(data);
    String _hash = hex.encode(topicHash.bytes);
    return _hash;
  }
}
