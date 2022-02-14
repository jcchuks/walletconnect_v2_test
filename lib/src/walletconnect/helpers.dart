import 'dart:convert';
import 'dart:developer';

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
import 'package:app/src/walletconnect/wc_client2.dart';
import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_events.dart';
import 'package:app/src/walletconnect/wc_state.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';

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

  static Future<SecretKey> getSharedKeyForPairingSettlement(
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
    //returns sha256 hash of the shared key.

    var topicSha = await Sha256().hash(await sharedKey.extractBytes());
    var topic = topicSha.bytes;
    return hex.encode(topic);
  }

  static Future<String> pairingSettlement(
      {required WcLibCore core,
      required PairingSuccessResponse pairingSuccessResponse}) async {
    State state = core.state;
    SecretKey sharedKey = await getSharedKeyForPairingSettlement(
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
    core.state.isPariringSettled = true;
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
    var sharedKey = await getSharedKeyForPairingSettlement(
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
    log(topic);
    log(core.state.settledPairingsMap.keys.first);
    core.state.isSessionSettled = true;
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

  static Future<String> encrypt(
      {required String sharedKey,
      required String message,
      required String publicKey}) async {
    List<SecretKey> keys =
        await Helpers.getEncryptionDecryptionKeys(sharedKey: sharedKey);
    SecretKey encryptionSecretKey = keys[0];
    SecretKey authenticationSecretKey = keys[1];

    var messageBytes = utf8.encode(message);

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    List<int> nonce = algorithm.newNonce();

    final secret = await algorithm.encrypt(messageBytes,
        secretKey: encryptionSecretKey, nonce: nonce);

    Hmac mac = Hmac.sha256();
    List<int> msg = List.from(nonce)
      ..addAll(hex.decode(publicKey))
      ..addAll(secret.cipherText);
    Mac messageMac =
        await mac.calculateMac(msg, secretKey: authenticationSecretKey);

    String nonceStr = hex.encode(nonce);
    String macStr = hex.encode(messageMac.bytes);
    String cipherTxt = hex.encode(secret.cipherText);

    var data = '$nonceStr$publicKey$macStr$cipherTxt';

    return data;
  }

// @TODO - return 'msg' as custom type containing iv, pk, mac, cipher.
  static String getCommaSeparatedEncryptedDataAsHexString(
      {required String data}) {
    int nonceEnds = 32;
    int publicKeyEnds = 96;
    int macEnds = 160;

    String nonceStr = data.substring(0, nonceEnds);

    String publicKeyStr = data.substring(nonceEnds, publicKeyEnds);
    String macStr = data.substring(publicKeyEnds, macEnds);
    String cipherStr = data.substring(macEnds);
    var msg = '$nonceStr,$publicKeyStr,$macStr,$cipherStr';

    return msg;
  }

// @TODO - replace 'message' with a custom type containing iv, pk, mac, cipher.
  static Future<String> decrypt(
      {required String sharedKey, required String message}) async {
    String nonce, publicKey, macStr, cipherText = '';
    if (!message.contains(',')) {
      throw WcException(
          type: WcErrorType.invalidValue,
          msg:
              "got $message. want message that contains 'iv,publicKey,mac,cipherText'");
    }
    var msgArray = message.split(",");
    if (msgArray.length != 4) {
      throw WcException(
          type: WcErrorType.invalidValue,
          msg:
              "got $message with length ${msgArray.length}. want message that contains 'iv,publicKey,mac,cipherText'");
    }

    List<SecretKey> keys =
        await Helpers.getEncryptionDecryptionKeys(sharedKey: sharedKey);
    SecretKey decryptionSecretKey = keys[0];
    SecretKey authenticationSecretKey = keys[1];

    nonce = msgArray[0];
    publicKey = msgArray[1];
    macStr = msgArray[2];
    cipherText = msgArray[3];

    var cipherTextBytes = hex.decode(cipherText);
    log("public key: : " + publicKey);

    //------------ verify mac
    Hmac mac = Hmac.sha256();
    Mac messageMac = await mac.calculateMac(
        hex.decode(nonce) + hex.decode(publicKey) + cipherTextBytes,
        secretKey: authenticationSecretKey);

    if (hex.encode(messageMac.bytes) != macStr) {
      throw WcException(
          type: WcErrorType.invalidValue,
          msg:
              "got mac string as ${hex.encode(messageMac.bytes)}, received '$macStr' with invalid mac");
    }

    //---------- decrypt cipherText
    SecretBox secretBox =
        SecretBox(cipherTextBytes, nonce: hex.decode(nonce), mac: Mac.empty);

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    final messageBytes =
        await algorithm.decrypt(secretBox, secretKey: decryptionSecretKey);
    final decodedPayload = utf8.decode(messageBytes);

    return decodedPayload;
  }

  static Future<String> sha256({required String msg}) async {
    final hashAlgorithm = Sha256();
    Hash topicHash = await hashAlgorithm.hash(utf8.encode(msg));
    String _hash = hex.encode(topicHash.bytes);
    return _hash;
  }
}
