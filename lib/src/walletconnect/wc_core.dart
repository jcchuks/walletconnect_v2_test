import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:app/src/walletconnect/helpers.dart';
import 'package:app/src/walletconnect/models/json_rpc_request.dart';
import 'package:app/src/walletconnect/models/pairing_proposal.dart';
import 'package:app/src/walletconnect/models/pairing_proposer.dart';
import 'package:app/src/walletconnect/models/params.dart';
import 'package:app/src/walletconnect/models/reason.dart';
import 'package:app/src/walletconnect/models/session_proposal.dart';
import 'package:app/src/walletconnect/models/waku_publish_request.dart';
import 'package:app/src/walletconnect/models/waku_publish_response.dart';
import 'package:app/src/walletconnect/models/waku_subscribe_request.dart';
import 'package:app/src/walletconnect/models/waku_subscribe_response.dart';
import 'package:app/src/walletconnect/models/waku_subscription_request.dart';
import 'package:app/src/walletconnect/models/waku_unsubscribe_request.dart';
import 'package:app/src/walletconnect/wc_crypto2.dart';
import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:app/src/walletconnect/wc_events.dart';
import 'package:app/src/walletconnect/wc_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:convert/convert.dart';

typedef EventCallBack = void Function(Map<String, dynamic> jsonRpcParams);

class WcLibCore {
  late WebSocketChannel _webSocket;
  Stream _socketStream = const Stream.empty();
  WebSocketSink? _socketSink;
  static int wakuSubscribeId = 1;
  static int wakuPublishId = 2;
  static String wakuSubscriptionId = '';
  Map<String, EventCallBack>? clientCallbacks;
  State state;

  static int wakuUnsubscribeId = 3;

  WcLibCore({required this.state, this.clientCallbacks});

  bool isConnected = false;

  connect() {
    String socketUri = Helpers.getRelayUri(state: state);
    final bridgeUri = Uri.parse(socketUri);
    log("socketuri: " + socketUri);
    _webSocket = WebSocketChannel.connect(bridgeUri);
    isConnected = true;
    // if (fromSessionStore) {
    //   onConnect?.call();
    // }
    Helpers.checkString(state.uriParameters.topic);
    state.pairingProposal = PairingProposal(
        topic: state.uriParameters.topic!,
        relay: state.uriParameters.relay,
        pairingProposer: PairingProposer(
            publicKey: state.uriParameters.publicKey!,
            controller: state.uriParameters.controller));
    _socketStream = _webSocket.stream;
    _socketSink = _webSocket.sink;
    _listen();

    subscribe(topic: state.uriParameters.topic!);
  }

  proposeSession({required SessionProposal sessionProposal}) {
    state.sessionProposal = sessionProposal;
    if (isConnected) {
      Events.onWcSessionPropose(
          payload: JsonRpcRequest(method: Events.internalDummyMethod),
          core: this);
    } else {
      throw WcException(
          type: WcErrorType.unknownOperation,
          msg: "No pairing has been established");
    }
  }

  disconnect({required String topic}) {
    if (state.settledPairingsMap.containsKey(topic)) {
      JsonRpcRequest jsonRpcRequest = JsonRpcRequest(
          method: Events.wcPairingDelete,
          params: Params(data: Reason(reason: "End pairing").toJson()));

      Events.wcEvents[Events.wcPairingDelete]!(
          payload: jsonRpcRequest, core: state, callBack: null);
    }
    unsubscribe(topic: topic);
    isConnected = false;
    state.reset();
    _socketSink!.close(WebSocketStatus.normalClosure);
  }

  subscribe({required String topic}) {
    final message = WakuSubscribeRequest(
            id: wakuSubscribeId, wakuParams: WakuSubscibeParams(topic: topic))
        .toJson();
    String msg = jsonEncode(message);
    log("Subscribe msg: " + msg);
    _send(data: msg);
  }

  unsubscribe({required String topic}) {
    final message = WakuUnsubscribeRequest(
        id: wakuUnsubscribeId,
        params: WakuUnsubscibeParams(id: wakuSubscriptionId, topic: topic));
    String encodedMessage = jsonEncode(message.toJson());
    log("Unsubscribe msg: " + encodedMessage);
    _send(data: encodedMessage);
  }

  publish(
      {required String message, required String topic, int ttl = 86400}) async {
    if (state.settledPairingsMap.containsKey(topic)) {
      message = await WcCrypto2.encrypt(
          sharedKey: state.pairingSettled.sharedKey,
          message: message,
          publicKey: state.pairingSettled.self!.publicKey!);
    }

    var jsonData = WakuPublishRequest(
            id: wakuPublishId,
            wakuParams:
                WakuPublishParams(message: message, topic: topic, ttl: ttl))
        .toJson();
    String data = jsonEncode(jsonData);

    _send(data: data);
  }

  EventCallBack? getClientCallBack(String method) {
    if (clientCallbacks?.isEmpty ?? true) {
      return null;
    }
    return clientCallbacks![method];
  }

  void _onWakuSubscriptionRequest(
      {required Map<String, dynamic> wakuSubscriptionJsonMap}) async {
    WakuSubscriptionRequest wakuSubscriptionRequest =
        WakuSubscriptionRequest.fromJson(wakuSubscriptionJsonMap);

    Map<String, dynamic> payload = await decodeReceivedJsonRpcMessage(
        message: wakuSubscriptionRequest.params.data.message,
        topic: wakuSubscriptionRequest.params.data.topic);

    String subId = wakuSubscriptionRequest.params.id;
    if (wakuSubscriptionId != subId) {
      log("Subscription ID received  " + subId + "want " + wakuSubscriptionId);
      return;
    }
    ;
    log("Received payload");
    log(payload.toString());
    // type JsonRpcResponse = JsonRpcResult | JsonRpcError;
    JsonRpcRequest wcJsonRpcPayload = JsonRpcRequest.fromJson(payload);

    //JsonRpcRequest payload, required State state, required Network network, EventCallBack? callBack
    Events.wcEvents[wcJsonRpcPayload.method]!(
        payload: wcJsonRpcPayload,
        core: this,
        callBack: getClientCallBack(wcJsonRpcPayload.method));
  }

  _send({required String data}) {
    _socketSink!.add(data);
  }

  void _handleOtherRelayEvents(Map<String, dynamic> data) {
    if (Helpers.isSubscribeEvent(data)) {
      var resp = WakuSubscribeResponse.fromJson(data);
      wakuSubscriptionId = resp.result!;
      log("Received subscribe event with subscriptionId " + wakuSubscriptionId);
    } else {
      var resp = WakuPublishResponse.fromJson(data);
      log("Received on handlingOtherRelay Events " + resp.result.toString());
    }
  }

  _listen() {
    _socketStream.listen(
      (event) async {
        log('DATA: $event');
        final Map<String, dynamic> decodedRawJson = json.decode("$event");

        if (Helpers.isSubscriptionEvent(decodedRawJson)) {
          log("Received subscription event");
          _onWakuSubscriptionRequest(wakuSubscriptionJsonMap: decodedRawJson);
        } else {
          _handleOtherRelayEvents(decodedRawJson);
        }
      },
      onError: (error) {
        log('onError $isConnected CloseCode ${_webSocket.closeCode} $error');
        state.reset();
        // onFailure?.call('$error');
      },
      onDone: () {
        if (isConnected) {
          log('onDone $isConnected CloseCode ${_webSocket.closeCode} ${_webSocket.closeReason}');
          state.reset();
          // onDisconnect?.call(_webSocket.closeCode, _webSocket.closeReason);
        }
      },
    );
  }

  Future<Map<String, dynamic>> decodeReceivedJsonRpcMessage(
      {required String message, required String topic}) async {
    String jsonString;
    if (state.settledPairingsMap.containsKey(topic)) {
      log("receieved encrypted msg ");
      jsonString = await WcCrypto2.decrypt(
          sharedKey: state.pairingSettled.sharedKey, message: message);
    } else {
      var msgBytes = hex.decode(message);
      jsonString = utf8.decode(msgBytes);
    }

    log("Decoded Received Json string  " + jsonString);
    return jsonDecode(jsonString);
  }
}
