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
import 'package:app/src/walletconnect/wc_crypto.dart';
import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_events.dart';
import 'package:app/src/walletconnect/wc_state.dart';
import 'package:convert/convert.dart';

//cryptography library pointycastle
// import 'package:pointycastle/paddings/pkcs7.dart';

//cryptography library
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
    return await WcCrypto.getSha256(data: await sharedKey.extractBytes());
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

  // static int _addPadding(List<int> data, int offset) {
  //   var code = (data.length - offset);

  //   while (offset < data.length) {
  //     data[offset] = code;
  //     offset++;
  //   }

  //   return code;
  // }

  // static List<int> addPkcs7Padding({required String message}) {
  //   List<int> data = utf8.encode(message).toList();
  //   int msgLengthInBytes = data.length;
  //   //AES 256 has a block size of 32 bytes hence find remainder
  //   // pkcs5 whose block size is 8 is compatible with pkcs7 since 8 is a factor
  //   // of 256.
  //   const int blockSize = 8;
  //   int blockModulo = msgLengthInBytes % blockSize;
  //   int padRemainderBlockCount = blockSize - blockModulo;
  //   data.addAll(
  //       List.generate(padRemainderBlockCount, (index) => index).toList());

  //   Uint8List bytes = Uint8List.fromList(data);
  //   var paddingCount = PKCS7Padding().addPadding(bytes, msgLengthInBytes);
  //   log(paddingCount.toString() +
  //       " " +
  //       padRemainderBlockCount.toString() +
  //       " " +
  //       bytes.length.toString() +
  //       " " +
  //       msgLengthInBytes.toString());
  //   assert(paddingCount == padRemainderBlockCount);
  //   assert(bytes.length == msgLengthInBytes + padRemainderBlockCount);
  //   return bytes;
  // }

}
