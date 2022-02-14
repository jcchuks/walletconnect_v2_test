import 'dart:convert';
import 'dart:developer';

import 'package:app/src/walletconnect/helpers.dart';
import 'package:app/src/walletconnect/models/json_rpc_request.dart';
import 'package:app/src/walletconnect/models/json_rpc_result.dart';
import 'package:app/src/walletconnect/models/pairing_failure_response.dart';
import 'package:app/src/walletconnect/models/pairing_state.dart';
import 'package:app/src/walletconnect/models/pairing_success_response.dart';
import 'package:app/src/walletconnect/models/params.dart';
import 'package:app/src/walletconnect/models/reason.dart';
import 'package:app/src/walletconnect/models/result.dart';
import 'package:app/src/walletconnect/models/session_request.dart';
import 'package:app/src/walletconnect/models/session_success_response.dart';
import 'package:app/src/walletconnect/wc_core.dart';
import 'package:app/src/walletconnect/wc_state.dart';

class Events {
  static int ingressJsonRpcId = 1;
  static int egressJsonRpcId = 2;

  static const String wcPairingApprove = "wc_pairingApprove";
  static const String wcPairingUpdate = "wc_pairingUpdate";
  static const String wcPairingReject = "wc_pairingReject";
  static const String wcPairingUpgrade = "wc_pairingUpgrade";
  static const String wcPairingDelete = "wc_pairingDelete";
  static const String wcPairingPayload = "wc_pairingPayload";
  static const String wcPairingPing = "wc_pairingPing";
  static const String wcPairingNotification = "wc_pairingNotification";
  static const String wcSessionPropose = "wc_sessionPropose";
  static const String wcSessionApprove = "wc_sessionApprove";
  static const String wcSessionReject = "wc_sessionReject";
  static const String wcSessionUpdate = "wc_sessionUpdate";
  static const String wcSessionUpgrade = "wc_sessionUpgrade";
  static const String wcSessionDelete = "wc_sessionDelete";
  static const String wcSessionPayload = "wc_sessionPayload";
  static const String wcSessionPing = "wc_sessionPing";
  static const String wcSessionNotification = "wc_sessionNotification";
  static const String internalDummyMethod = "internalDummyMethod";

  static final Map<String, Function> wcEvents = {
    wcPairingApprove: _onWcPairingApprove,
    wcPairingUpdate: _onWcPairingUpdate,
    wcPairingReject: _onWcPairingReject,
    wcPairingUpgrade: _onWcPairingUpgrade,
    wcPairingDelete: _onWcPairingDelete,
    wcPairingPayload: _onWcPairingPayload,
    wcPairingPing: _onWcPairingPing,
    wcPairingNotification: _onWcPairingNotification,
    wcSessionPropose: onWcSessionPropose,
    wcSessionApprove: _onWcSessionApprove,
    wcSessionReject: _onWcSessionReject,
    wcSessionUpdate: _onWcSessionUpdate,
    wcSessionUpgrade: _onWcSessionUpgrade,
    wcSessionDelete: _onWcSessionDelete,
    wcSessionPayload: _onWcSessionPayload,
    wcSessionPing: _onWcSessionPing,
    wcSessionNotification: _onWcSessionNotification
  };

  static void _onWcPairingApprove(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) async {
    if (Helpers.isFailedResponse(payload.params!.data)) {
      //call failure method
      return;
    }
    log("Handling pairing Approved");
    //State state = core.state;
    PairingSuccessResponse pairingSuccessResponse =
        PairingSuccessResponse.fromJson(payload.params!.data!);
    String derivedTopic = await Helpers.pairingSettlement(
        core: core, pairingSuccessResponse: pairingSuccessResponse);

    _sendWcEventSuccessResponse(core: core, topic: derivedTopic);
    core.subscribe(topic: derivedTopic);
  }

  static void _onWcPairingReject(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {
    State state = core.state;
    Helpers.raiseExceptionOnEmotyOrInvalidJsonRpcRequestPayloadParams(
        params: payload.params);
    PairingFailureResponse reason =
        PairingFailureResponse.fromJson(payload.params!.data!);
    String topic = state.pairingProposal.topic;
    core.state.pairingFailureResponse = reason;
    Helpers.removePairingProposal(core);
    _sendWcEventSuccessResponse(core: core, topic: topic);
    callBack?.call(reason.toJson());
  }

  static void _onWcPairingUpdate(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {
    PairingState state = PairingState.fromJson(payload.params!.data!['state']);
    core.state.pairingSettled.state = state;
    _sendWcEventSuccessResponse(
        core: core, topic: core.state.pairingSettled.topic);

    // log("Pairing updated " + core.state.pairingSettled.topic);
    // log("Received topic " + payload.params!.data!['topic']);
  }

  static void _onWcPairingUpgrade(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcPairingDelete(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {
    core.publish(
        message: jsonEncode(payload), topic: core.state.pairingSettled.topic);
  }

  static Future<void> _onWcPairingPayload(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) async {
    State state = core.state;
    assert(payload.method == internalDummyMethod);
    JsonRpcRequest jsonRpcRequest = JsonRpcRequest(
        method: wcPairingPayload, params: Params(data: payload.paramsAsJson()));
    String encodedJsonRpcRequest = jsonEncode(jsonRpcRequest);
    log(encodedJsonRpcRequest);
    await core.publish(
        message: encodedJsonRpcRequest,
        topic: state.sessionProposal.signal.params.topic);
  }

  static void _onWcPairingPing(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcPairingNotification(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static Future<void> onWcSessionPropose(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) async {
    JsonRpcRequest sessionProposeRequest = JsonRpcRequest(
        method: wcSessionPropose,
        params: Params(data: core.state.sessionProposal.toJson()));

    //for correctness - otherwise moving session req to onWcPairingPayload can be more efficient.
    SessionRequest request = SessionRequest(
        request: Params(data: sessionProposeRequest.methodAndParamsAsJson()));

    await _onWcPairingPayload(
        payload: JsonRpcRequest(
            method: internalDummyMethod,
            params: Params(data: request.toJson())),
        core: core,
        callBack: callBack);
  }

  static void _onWcSessionApprove(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {
    if (payload.params?.data?.isEmpty ?? true) {
      return;
    }
    State state = core.state;
    SessionSuccessResponse sessionSuccessResponse =
        SessionSuccessResponse.fromJson(payload.params!.data!);
    Helpers.sessionSettlement(
        core: core, sessionSuccessResponse: sessionSuccessResponse);
    _sendWcEventSuccessResponse(
        core: core, topic: state.sessionProposal.signal.params.topic);
  }

  static void _onWcSessionReject(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcSessionUpdate(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcSessionUpgrade(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcSessionDelete(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {
    State state = core.state;
    Reason reason = Reason(reason: "End Session");
    Params params = Params(data: reason.toJson());
    JsonRpcRequest jsonRpcRequest = JsonRpcRequest(
        method: wcSessionDelete, params: params, id: egressJsonRpcId);
    String encodedJsonRpcRequest = jsonEncode(jsonRpcRequest.toJson());

    Helpers.removeSettledSession(core: core);

    String topic = state.sessionSettled.topic;
    core.publish(message: encodedJsonRpcRequest, topic: topic);
    callBack?.call(params.toJson());
  }

  static void _onWcSessionPayload(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcSessionPing(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcSessionNotification(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _sendWcEventSuccessResponse(
      {required WcLibCore core, required String topic}) {
    JsonRpcResult jsonRpcResult = JsonRpcResult(
        id: egressJsonRpcId,
        result: Result(
          resBool: true,
        ));
    String encodedJsonRpcRequest = jsonEncode(jsonRpcResult.toJson());
    core.publish(message: encodedJsonRpcRequest, topic: topic);
  }
}
