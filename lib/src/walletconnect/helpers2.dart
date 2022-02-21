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
import 'package:app/src/walletconnect/wc_crypto2.dart';
import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_events.dart';
import 'package:app/src/walletconnect/wc_state.dart';
import 'package:convert/convert.dart';

import 'package:cryptography/cryptography.dart';

class Helpers2 {
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
      {required List<int> sharedKey}) async {
    return WcCrypto2.getSha256(data: Uint8List.fromList(sharedKey));
  }

  static Future<String> pairingSettlement(
      {required WcLibCore core,
      required PairingSuccessResponse pairingSuccessResponse}) async {
    State state = core.state;
    SecretKey sharedKey = await getSharedKey(
        keyPair: core.state.keyPair,
        responderPublicKey: pairingSuccessResponse.responder!.publicKey!);
    var topic =
        await getTopicOnSettlement(sharedKey: await sharedKey.extractBytes());
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
    var topic =
        await getTopicOnSettlement(sharedKey: await sharedKey.extractBytes());
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
}
