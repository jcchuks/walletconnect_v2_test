import 'dart:convert';
import 'dart:core';
import 'dart:developer';
import 'dart:io';

import 'package:app/src/walletconnect/models/app_metadata.dart';
import 'package:app/src/walletconnect/models/blockchain.dart';
import 'package:app/src/walletconnect/models/json_rpc_request.dart';
import 'package:app/src/walletconnect/models/json_rpc_result.dart';
import 'package:app/src/walletconnect/models/jsonrpc.dart';
import 'package:app/src/walletconnect/models/pairing_failure_response.dart';
import 'package:app/src/walletconnect/models/pairing_participant.dart';
import 'package:app/src/walletconnect/models/pairing_permissions.dart';
import 'package:app/src/walletconnect/models/pairing_proposal.dart';
import 'package:app/src/walletconnect/models/pairing_proposed_permissions.dart';
import 'package:app/src/walletconnect/models/pairing_proposer.dart';
import 'package:app/src/walletconnect/models/pairing_proposer_params.dart';
import 'package:app/src/walletconnect/models/pairing_settled.dart';
import 'package:app/src/walletconnect/models/pairing_signal.dart';
import 'package:app/src/walletconnect/models/pairing_success_response.dart';
import 'package:app/src/walletconnect/models/params.dart';
import 'package:app/src/walletconnect/models/reason.dart';
import 'package:app/src/walletconnect/models/relay.dart';
import 'package:app/src/walletconnect/models/result.dart';
import 'package:app/src/walletconnect/models/sequence.dart';
import 'package:app/src/walletconnect/models/session_participant.dart';
import 'package:app/src/walletconnect/models/session_permissions.dart';
import 'package:app/src/walletconnect/models/session_proposal.dart';
import 'package:app/src/walletconnect/models/session_proposed_permissions.dart';
import 'package:app/src/walletconnect/models/session_proposer.dart';
import 'package:app/src/walletconnect/models/session_request.dart';
import 'package:app/src/walletconnect/models/session_settled.dart';
import 'package:app/src/walletconnect/models/session_signal.dart';
import 'package:app/src/walletconnect/models/session_success_response.dart';
import 'package:app/src/walletconnect/models/uri_parameters.dart';
import 'package:app/src/walletconnect/models/waku_publish_request.dart';
import 'package:app/src/walletconnect/models/waku_publish_response.dart';
import 'package:app/src/walletconnect/models/waku_subscribe_request.dart';
import 'package:app/src/walletconnect/models/waku_subscribe_response.dart';
import 'package:app/src/walletconnect/models/waku_subscription_request.dart';
import 'package:app/src/walletconnect/models/waku_unsubscribe_request.dart';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';
import 'package:web3dart/crypto.dart';
// import 'package:wallet_connect/models/ethereum/wc_ethereum_sign_message.dart';
// import 'package:wallet_connect/models/ethereum/wc_ethereum_transaction.dart';
// import 'package:wallet_connect/models/exception/exceptions.dart';
// import 'package:wallet_connect/models/jsonrpc/json_rpc_error.dart';
// import 'package:wallet_connect/models/jsonrpc/json_rpc_error_response.dart';
// import 'package:wallet_connect/models/jsonrpc/json_rpc_request.dart';
// import 'package:wallet_connect/models/jsonrpc/json_rpc_response.dart';
// import 'package:wallet_connect/models/message_type.dart';
// import 'package:wallet_connect/models/session/wc_approve_session_response.dart';
// import 'package:wallet_connect/models/session/wc_session.dart';
// import 'package:wallet_connect/models/session/wc_session_request.dart';
// import 'package:wallet_connect/models/session/wc_session_update.dart';
// import 'package:wallet_connect/models/wc_encryption_payload.dart';
// import 'package:wallet_connect/models/wc_method.dart';
// import 'package:wallet_connect/models/wc_peer_meta.dart';
// import 'package:wallet_connect/models/wc_socket_message.dart';
// import 'package:wallet_connect/wc_cipher.dart';
// import 'package:wallet_connect/wc_session_store.dart';
// import 'package:web3dart/crypto.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import "wc_session2.dart";

// typedef SessionRequest = void Function(int id, WCPeerMeta peerMeta);
// typedef SocketError = void Function(dynamic message);
// typedef SocketClose = void Function(int? code, String? reason);
// typedef EthSign = void Function(int id, WCEthereumSignMessage message);
// typedef EthTransaction = void Function(
//     int id, WCEthereumTransaction transaction);
// typedef CustomRequest = void Function(int id, String payload);

typedef void EventCallBack(Map<String, dynamic> jsonRpcParams);

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
    wcPairingUpdate: _onWcPairingReject,
    wcPairingReject: _onWcPairingUpdate,
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
      EventCallBack? callBack}) {
    if (Helpers.isFailedResponse(payload.params!.data)) {
      //call failure method
      return;
    }
    log("Handling pairing Approved");
    State state = core.state;
    PairingSuccessResponse pairingSuccessResponse =
        PairingSuccessResponse.fromJson(payload.params!.data!);
    Helpers.pairingSettlement(
        core: core, pairingSuccessResponse: pairingSuccessResponse);

    _sendWcEventSuccessResponse(core: core, topic: state.pairingProposal.topic);
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
      EventCallBack? callBack}) {}

  static void _onWcPairingUpgrade(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static void _onWcPairingDelete(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) {}

  static Future<void> _onWcPairingPayload(
      {required JsonRpcRequest payload,
      required WcLibCore core,
      EventCallBack? callBack}) async {
    State state = core.state;
    assert(payload.method == internalDummyMethod);
    JsonRpcRequest jsonRpcRequest = JsonRpcRequest(
        method: wcPairingPayload, params: Params(data: payload.paramsAsJson()));
    String encodedJsonRpcRequest = jsonEncode(jsonRpcRequest);

    await core.publish(
        message: encodedJsonRpcRequest,
        topic: state.sessionProposal.signal.params.topic,
        shouldEncrypt: true);
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

enum WcErrorType { emptyValue, invalidValue, unknownOperation }

class WcException implements Exception {
  final WcErrorType type;
  final String? msg;

  WcException({required this.type, this.msg});

  @override
  String toString() => "WcException.$type: $msg";
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
        hexToBytes(responderPublicKey),
        type: KeyPairType.x25519);
    SecretKey sharedKey = await algorithm.sharedSecretKey(
        keyPair: keyPair, remotePublicKey: remotePublicKey);
    return sharedKey;
  }

  static Future<String> sharedKeyString({required SecretKey secretKey}) async {
    List<int> bytes = await secretKey.extractBytes();
    return bytesToHex(bytes);
  }

  static Future<String> getTopicOnSettlement(
      {required SecretKey sharedKey}) async {
    //returns sha256 hash of the shared key.

    var topicSha = await Sha256().hash(await sharedKey.extractBytes());
    var topic = topicSha.bytes;
    return bytesToHex(topic);
  }

  static void pairingSettlement(
      {required WcLibCore core,
      required PairingSuccessResponse pairingSuccessResponse}) async {
    State state = core.state;
    SecretKey sharedKey = await getSharedKeyForPairingSettlement(
        keyPair: core.state.keyPair,
        responderPublicKey: pairingSuccessResponse.responder!.publicKey!);
    var topic = await getTopicOnSettlement(sharedKey: sharedKey);
    var publicKey = state.pairingProposal.pairingProposer!.publicKey;
    var self = PairingParticipant(publicKey: publicKey);
    // log("pairingSuccessResponse.topic :" + pairingSuccessResponse.topic!);
    log("Generated topic :" + topic);
    log("original topic :" + state.pairingProposal.topic);
    // assert(pairingSuccessResponse.topic == topic);

    var sharedKeyAsString = await sharedKeyString(secretKey: sharedKey);
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
    log("Pairing Settled");
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
        appMetadata: state.sessionProposal.sessionProposer!.appMetadata);
    assert(sessionSuccessResponse.topic ==
        topic); //if fails, know sharedKey is invalid

    var sharedKeyAsString = await sharedKeyString(secretKey: sharedKey);

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
          sessionProposedPermissions:
              state.sessionProposal.sessionProposedPermissions),
    );
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
    List<int> sharedKeyBytes = hexToBytes(sharedKey);

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

    var messageBytes = utf8.encode(message);
    final secret =
        await algorithm.encrypt(messageBytes, secretKey: encryptionSecretKey);

    Hmac mac = Hmac.sha256();
    Mac messageMac = await mac.calculateMac(secret.cipherText,
        secretKey: authenticationSecretKey);
    String hexMac = String.fromCharCodes(messageMac.bytes);

    return "${secret.nonce},$publicKey,$hexMac,${secret.cipherText}";
  }

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

    List<int> sharedKeyBytes = hexToBytes(sharedKey);

    Sha512 encAuthHash = Sha512();
    Hash encAuthKeys = await encAuthHash.hash(sharedKeyBytes);

    int partition = encAuthKeys.bytes.length ~/ 2;

    var decryptionKeys = encAuthKeys.bytes.getRange(0, partition).toList();
    var authenticationKeys = encAuthKeys.bytes
        .getRange(partition, encAuthKeys.bytes.length)
        .toList();

    var algorithm = AesCbc.with256bits(macAlgorithm: MacAlgorithm.empty);
    SecretKey decryptionSecretKey =
        await algorithm.newSecretKeyFromBytes(decryptionKeys);
    SecretKey authenticationSecretKey =
        await algorithm.newSecretKeyFromBytes(authenticationKeys);

    nonce = msgArray[0];
    publicKey = msgArray[1];
    macStr = msgArray[2];
    cipherText = msgArray[3];

    var cipherTextBytes = utf8.encode(cipherText);
    var macStrBytes = utf8.encode(macStr);

    //------------ verify mac
    Hmac mac = Hmac.sha256();
    Mac messageMac = await mac.calculateMac(cipherTextBytes,
        secretKey: authenticationSecretKey);

    if (messageMac.bytes.hashCode != macStrBytes.hashCode) {
      throw WcException(
          type: WcErrorType.invalidValue,
          msg:
              "got mac string as ${utf8.decode(messageMac.bytes)}, received '$message' with invalid mac");
    }

    //---------- decrypt cipherText
    SecretBox secretBox =
        SecretBox(cipherTextBytes, nonce: utf8.encode(nonce), mac: Mac.empty);

    final messageBytes =
        await algorithm.decrypt(secretBox, secretKey: decryptionSecretKey);
    final decodedPayload = utf8.decode(messageBytes);
    return decodedPayload;
  }

  static Future<String> sha256({required String msg}) async {
    final hashAlgorithm = Sha256();
    Hash topicHash = await hashAlgorithm.hash(utf8.encode(msg));
    String _hash = bytesToHex(topicHash.bytes);
    return _hash;
  }
}

class CAIP {
  static String caipHandshake = "caip_handshake";
  static String caipRequest = "caip_request";
}

class EtheriumMethods {
  static const String ethSendTransaction = "eth_sendTransaction";
  static const String ethSignTransaction = "eth_signTransaction";
  static const String ethSign = "eth_sign";
  static const String personalSign = "personal_sign";

  static List<String> getMethodList() {
    return [ethSendTransaction, ethSignTransaction, ethSign, personalSign];
  }
}

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

  bool _isConnected = false;

  connect() {
    String socketUri = Helpers.getRelayUri(state: state);
    final bridgeUri = Uri.parse(socketUri);
    log("socketuri: " + socketUri);
    _webSocket = WebSocketChannel.connect(bridgeUri);
    _isConnected = true;
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
    if (_isConnected) {
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
    unsubscribe(topic: topic);
    _isConnected = false;
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
      {required String message,
      required String topic,
      int ttl = 86400,
      bool shouldEncrypt = false}) async {
    if (shouldEncrypt) {
      message = await Helpers.encrypt(
          sharedKey: state.pairingSettled.sharedKey,
          message: message,
          publicKey: state.pairingSettled.permissions!.controller.publicKey);
    }

    var jsonData = WakuPublishRequest(
            id: wakuPublishId,
            wakuParams:
                WakuPublishParams(message: message, topic: topic, ttl: ttl))
        .toJson();
    String data = jsonEncode(jsonData);
    log("publishing response");
    log(data);
    _send(data: data);
  }

  EventCallBack? getClientCallBack(String method) {
    if (clientCallbacks?.isEmpty ?? true) {
      return null;
    }
    return clientCallbacks![method];
  }

  void _onWakuSubscriptionRequest(
      {required Map<String, dynamic> wakuSubscriptionJsonMap}) {
    WakuSubscriptionRequest wakuSubscriptionRequest =
        WakuSubscriptionRequest.fromJson(wakuSubscriptionJsonMap);

    //check whether to decrypt before decoding - Track state
    Map<String, dynamic> payload = decodeReceivedJsonRpcMessage(
        message: wakuSubscriptionRequest.params!.data!.message);
    String subId = wakuSubscriptionRequest.params!.id;
    assert(wakuSubscriptionId == subId);
    log("Received payload");
    log(payload.toString());
    // type JsonRpcResponse = JsonRpcResult | JsonRpcError;
    JsonRpcRequest wcJsonRpcPayload = JsonRpcRequest.fromJson(payload);

    if (Events.wcEvents[wcJsonRpcPayload.method] is Function) {
      //JsonRpcRequest payload, required State state, required Network network, EventCallBack? callBack
      Events.wcEvents[wcJsonRpcPayload.method]!(
          payload: wcJsonRpcPayload,
          core: this,
          callBack: getClientCallBack(wcJsonRpcPayload.method));
    }
  }

  sendPairingAck(JsonRpcResult message, String topic) {
    String messageToString = jsonEncode(message.toJson());
    publish(message: messageToString, topic: topic);
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
        log('onError $_isConnected CloseCode ${_webSocket.closeCode} $error');
        // _resetState();
        // onFailure?.call('$error');
      },
      onDone: () {
        if (_isConnected) {
          log('onDone $_isConnected CloseCode ${_webSocket.closeCode} ${_webSocket.closeReason}');
          // _resetState();
          // onDisconnect?.call(_webSocket.closeCode, _webSocket.closeReason);
        }
      },
    );
  }

  Map<String, dynamic> decodeReceivedJsonRpcMessage({required String message}) {
    String jsonString = utf8.decode(hexToBytes(message));
    log("Decoded Received Json string");
    log(jsonString);
    return jsonDecode(jsonString);
  }
}

class State {
  AppMetadata appMetadata;
  UriParameters uriParameters;
  PairingSignal pairingSignal;
  SimpleKeyPair keyPair;
  late PairingSettled pairingSettled;
  late PairingProposal pairingProposal;
  late PairingFailureResponse pairingFailureResponse;
  late SessionProposal sessionProposal;
  late SessionSettled sessionSettled;

  State(
      {required this.uriParameters,
      required this.appMetadata,
      required this.pairingSignal,
      required this.keyPair});
}

class BlockchainId {
  late String name;
  BlockchainId({required this.name});
}

class BlockChainIds {
  static BlockchainId etheriumMainet = BlockchainId(name: "eip155:1");
  static BlockchainId bitcoinMainet =
      BlockchainId(name: "bip122:000000000019d6689c085ae165831e93");

  static List<String> getChainMethods({required BlockchainId chain}) {
    if (chain.name == etheriumMainet.name) {
      return EtheriumMethods.getMethodList();
    }

    throw WcException(
        type: WcErrorType.invalidValue, msg: "Chain not supported");
  }
}

class WcClient {
  late WcLibCore core;
  late SimpleKeyPair keyPair;

  Map<String, EventCallBack>? clientCallbacks = {};
  // ---------- Methods ----------------------------------------------- //

  // initializes the client with persisted storage and a network connection
  Future<void> init(
      {bool controller = false,
      required AppMetadata metadata,
      required String relayProvider,
      required String topic,
      Map<String, EventCallBack>? callbacks}) async {
    var topicSha = await Helpers.sha256(msg: topic);
    //sha256.convert(utf8.encode()).toString();
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();

    clientCallbacks = callbacks;

    SimplePublicKey sPkey = await keyPair.extractPublicKey();
    var key = bytesToHex(sPkey.bytes);

    State state = State(
        uriParameters: UriParameters(
            controller: controller, publicKey: key, topic: topicSha),
        appMetadata: metadata,
        pairingSignal: PairingSignal(
            pairingProposerParams: PairingProposerParams(uri: relayProvider)),
        keyPair: keyPair);
    core = WcLibCore(state: state, clientCallbacks: clientCallbacks);
  }

  // for proposer to propose a session to a responder
  Future<String> connect() async {
    core.connect();
    return Helpers.getOutBandUri(state: core.state);
  }

  bool get isConnected => core._isConnected;

  proposeNewSession({
    required List<BlockchainId> blockChainIds,
  }) {
    List<String> chains = [];
    List<String> chainMethods = [];
    for (var chain in blockChainIds) {
      chains.add(chain.name);
      chainMethods.addAll(BlockChainIds.getChainMethods(chain: chain));
    }
    log(chainMethods.first.toString());
    State state = core.state;
    var permissions = SessionProposedPermissions(
        blockchain: Blockchain(chains: chains),
        jsonrpc: Jsonrpc(methods: chainMethods));
    var sessionProposal = SessionProposal(
        topic: state.pairingSettled.topic,
        relay: state.pairingSettled.relay,
        sessionProposedPermissions: permissions,
        sessionProposer: SessionProposer(
            publicKey: state.pairingSettled.self!
                .publicKey!, //should throw error if not exists
            controller: state.uriParameters.controller,
            appMetadata: state.appMetadata),
        signal:
            SessionSignal(params: Sequence(topic: state.pairingProposal.topic)),
        ttl: 8640);

    core.proposeSession(sessionProposal: sessionProposal);
  }

  // // for either to ping and verify peer is online
  // Future<void> ping({String topic}) {}
  // // for either to send notifications
  // Future<void> notify({
  //   String topic,
  //   Notification notification,
  // }) {}

  // for either to disconnect a session
  Future<void> disconnect({required String topic, Reason? reason}) async {
    var topicSha = await Helpers.sha256(msg: topic);
    core.disconnect(topic: topicSha);
  }

  //-----------proser can initiate end---------------- //

// // for proposer to request JSON-RPC
//   Future<dynamic> request(
//       {String topic, RequestArguments request, String? chainId}) {}

//   // for responder to receive a session proposal from a proposer
//   Future<Sequence> pair({String uri}) {}

//   // for responder to approve a session proposal
//   Future<Sequence> approve({
//     SessionProposal proposal,
//     SessionResponse response,
//   });
//   // for responder to reject a session proposal
//   Future<void> reject({SessionProposal proposal, Reason reason}) {}
//   // for responder to upgrade session permissions
//   Future<void> upgrade({String topic, SessionPermissions permissions}) {}
//   // for responder to update session state
//   Future<void> update({String topic, SessionState state}) {}

//   // for responder to respond JSON-RPC
//   Future<void> respond({String topic, JsonRpcResponse response}) {}
//   // ---------- Events ----------------------------------------------- //

}


// class WCClient {
//   late WebSocketChannel _webSocket;
//   Stream _socketStream = Stream.empty();
//   // ignore: close_sinks
//   WebSocketSink? _socketSink;
//   WCSession? _session;
//   WCPeerMeta? _peerMeta;
//   WCPeerMeta? _remotePeerMeta;
//   int _handshakeId = -1;
//   int? _chainId;
//   String? _peerId;
//   String? _remotePeerId;
//   bool _isConnected = false;

//   WCClient({
//     this.onSessionRequest,
//     this.onFailure,
//     this.onDisconnect,
//     this.onEthSign,
//     this.onEthSignTransaction,
//     this.onEthSendTransaction,
//     this.onCustomRequest,
//     this.onConnect,
//   });

//   final SessionRequest? onSessionRequest;
//   final SocketError? onFailure;
//   final SocketClose? onDisconnect;
//   final EthSign? onEthSign;
//   final EthTransaction? onEthSignTransaction, onEthSendTransaction;
//   final CustomRequest? onCustomRequest;
//   final Function()? onConnect;

//   WCSession? get session => _session;
//   WCPeerMeta? get peerMeta => _peerMeta;
//   WCPeerMeta? get remotePeerMeta => _remotePeerMeta;
//   int? get chainId => _chainId;
//   String? get peerId => _peerId;
//   String? get remotePeerId => _remotePeerId;
//   bool get isConnected => _isConnected;
//   String subscriptionId = "";

//   get Id => 2;

//   connectNewSession({
//     required WCSession session,
//     required WCPeerMeta peerMeta,
//   }) {
//     _connect(
//       session: session,
//       peerMeta: peerMeta,
//     );
//   }

//   // connectFromSessionStore(WCSessionStore sessionStore) {
//   //   _connect(
//   //     fromSessionStore: true,
//   //     session: sessionStore.session,
//   //     peerMeta: sessionStore.peerMeta,
//   //     remotePeerMeta: sessionStore.remotePeerMeta,
//   //     peerId: sessionStore.peerId,
//   //     remotePeerId: sessionStore.remotePeerId,
//   //     chainId: sessionStore.chainId,
//   //   );
//   // }

//   // WCSessionStore get sessionStore => WCSessionStore(
//   //       session: _session!,
//   //       peerMeta: _peerMeta!,
//   //       peerId: _peerId!,
//   //       remotePeerId: _remotePeerId!,
//   //       remotePeerMeta: _remotePeerMeta!,
//   //       chainId: _chainId!,
//   //     );

//   // approveSession({required List<String> accounts, int? chainId}) {
//   //   if (_handshakeId <= 0) {
//   //     throw HandshakeException();
//   //   }

//   //   if (chainId != null) _chainId = chainId;
//   //   final result = WCApproveSessionResponse(
//   //     chainId: _chainId,
//   //     accounts: accounts,
//   //     peerId: _peerId!,
//   //     peerMeta: _peerMeta!,
//   //   );
//   //   final response = JsonRpcResponse<Map<String, dynamic>>(
//   //     id: _handshakeId,
//   //     result: result.toJson(),
//   //   );
//   //   log('approveSession ${jsonEncode(response.toJson())}');
//   //   onConnect?.call();
//   //   _encryptAndSend(jsonEncode(response.toJson()));
//   // }

//   // Future<void> updateSession({
//   //   List<String>? accounts,
//   //   int? chainId,
//   //   bool approved = true,
//   // }) async {
//   //   final param = WCSessionUpdate(
//   //     approved: approved,
//   //     chainId: _chainId ?? chainId,
//   //     accounts: accounts,
//   //   );
//   //   final request = JsonRpcRequest(
//   //     id: DateTime.now().millisecondsSinceEpoch,
//   //     method: WCMethod.SESSION_UPDATE.toString(),
//   //     params: Params(data: param),
//   //   );
//   //   return _encryptAndSend(jsonEncode(request.toJson()));
//   // }

//   // rejectSession({String message = "Session rejected"}) {
//   //   if (_handshakeId <= 0) {
//   //     throw HandshakeException();
//   //   }

//   //   final response = JsonRpcErrorResponse(
//   //     id: _handshakeId,
//   //     error: JsonRpcError.serverError(message),
//   //   );
//   //   _encryptAndSend(jsonEncode(response.toJson()));
//   // }

//   // approveRequest<T>({
//   //   required int id,
//   //   required T result,
//   // }) {
//   //   final response = JsonRpcResponse<T>(
//   //     id: id,
//   //     result: result,
//   //   );
//   //   _encryptAndSend(jsonEncode(response.toJson()));
//   // }

//   // rejectRequest({
//   //   required int id,
//   //   String message = "Reject by the user",
//   // }) {
//   //   final response = JsonRpcErrorResponse(
//   //     id: id,
//   //     error: JsonRpcError.serverError(message),
//   //   );
//   //   _encryptAndSend(jsonEncode(response.toJson()));
//   // }

//   _connect({
//     required WCSession session,
//     required WCPeerMeta peerMeta,
//     bool fromSessionStore = false,
//     WCPeerMeta? remotePeerMeta,
//     String? peerId,
//     String? remotePeerId,
//     int? chainId,
//   }) {
//     // if (session == WCSession.empty()) {
//     //   throw InvalidSessionException();
//     // }

//     peerId ??= Uuid().v4();
//     _session = session;
//     _peerMeta = peerMeta;
//     _remotePeerMeta = remotePeerMeta;
//     _peerId = peerId;
//     _remotePeerId = remotePeerId;
//     _chainId = chainId;
//     String socketUri = session.toSockUri();
//     final bridgeUri = Uri.parse(socketUri);
//     log(socketUri);
//     _webSocket = WebSocketChannel.connect(bridgeUri);
//     _isConnected = true;
//     if (fromSessionStore) {
//       onConnect?.call();
//     }
//     _socketStream = _webSocket.stream;
//     _socketSink = _webSocket.sink;
//     _listen();
//     _subscribe(session.topic);
//     // _subscribe(peerId);
//   }

//   disconnect() {
//     _socketSink!.close(WebSocketStatus.normalClosure);
//   }

//   _subscribe(String topic) {
//     final message =
//         WakuSubscribeRequest(id: Id, wakuParams: Params(data: {"topic": topic}))
//             .toJson();
//     String msg = jsonEncode(message);
//     log("Subscribe msg: " + msg);
//     _socketSink!.add(msg);
//   }

//   // _invalidParams(int id) {
//   //   final response = JsonRpcErrorResponse(
//   //     id: id,
//   //     error: JsonRpcError.invalidParams("Invalid parameters"),
//   //   );
//   //   _encryptAndSend(jsonEncode(response.toJson()));
//   // }

//   Future<void> _encryptAndSend(String result) async {
//     final payload = await WCCipher.encrypt(result, _session!.key);
//     log('encrypted $payload');
//     final message = WCSocketMessage(
//       topic: _remotePeerId ?? _session!.topic,
//       type: MessageType.PUB,
//       payload: jsonEncode(payload.toJson()),
//     );
//     log('message ${jsonEncode(message.toJson())}');
//     _socketSink!.add(jsonEncode(message.toJson()));
//   }

//   _listen() {
//     _socketStream.listen(
//       (event) async {
//         log('DATA: $event');
//         final Map<String, dynamic> decoded = json.decode("$event");

//         if (Helpers.isSubscriptionEvent(decoded)) {
//           log("Received subscription event");
//           WakuSubscriptionRequest wakuSubscriptionRequest =
//               WakuSubscriptionRequest.fromJson(decoded);
//           Map<String, dynamic> payload = getPayload(wakuSubscriptionRequest);
//           var wcJsonPayload = JsonRpcRequest.fromJson(payload);

//           // final decryptedMessage = await _decrypt(wakuSubscriptionRequest);
//           _handleMessage(wcJsonPayload);
//         } else {
//           handleOtherRelayEvents(decoded);
//         }
//       },
//       onError: (error) {
//         log('onError $_isConnected CloseCode ${_webSocket.closeCode} $error');
//         _resetState();
//         onFailure?.call('$error');
//       },
//       onDone: () {
//         if (_isConnected) {
//           log('onDone $_isConnected CloseCode ${_webSocket.closeCode} ${_webSocket.closeReason}');
//           _resetState();
//           onDisconnect?.call(_webSocket.closeCode, _webSocket.closeReason);
//         }
//       },
//     );
//   }

//   Map<String, dynamic> getPayload(WakuSubscriptionRequest socketMessage) {
//     String jsonString = utf8.decode(hexToBytes(socketMessage.reason ?? ''));
//     log("Decoded String from Approve");
//     log(jsonString);
//     return jsonDecode(jsonString);
//   }

//   Future<String> _decrypt(WakuSubscriptionRequest socketMessage) async {
//     final payload =
//         WCEncryptionPayload.fromJson(jsonDecode(socketMessage.reason ?? ''));
//     final decrypted = await WCCipher.decrypt(payload, _session!.key);
//     log("DECRYPTED: $decrypted");
//     return decrypted;
//   }

//   _handleMessage(JsonRpcRequest payload) {
//     try {
//       //final request = JsonRpcRequest.fromJson(jsonDecode(payload));
//       if (payload.method != null) {
//         _handleRequest(payload);
//       } else {
//         // onCustomRequest?.call(request.id, payload);
//       }
//     } on InvalidJsonRpcParamsException catch (e) {
//       // _invalidParams(e.requestId);
//     }
//   }

//   void pairingSettle(PairingSuccessResponse req) {
//     //derive shared key from public key from x25519
//     //Calc next topic as sha256  hash of shared key
//   }

//   _publish({required String message, required String topic, int ttl = 86400}) {
//     var data = WakuPublishRequest(
//             id: Id,
//             wakuParams:
//                 WakuPublishParams(message: message, topic: topic, ttl: ttl))
//         .toJson();
//     String jsonData = jsonEncode(data);
//     log("publishing response");
//     log(jsonData);
//     _socketSink!.add(jsonData);
//   }

//   sendPairingAck(JsonRpcResult message, String topic) {
//     String messageToString = jsonEncode(message.toJson());
//     _publish(message: messageToString, topic: topic);
//   }

//   _handleRequest(JsonRpcRequest payload) {
//     if (payload.params == null) throw InvalidJsonRpcParamsException(payload.id);

//     switch (payload.method) {
//       case Events.wcPairingApprove:
//         if (Helpers.isFailedResponse(payload.params!.data)) {
//           //call failure method
//         }
//         PairingSuccessResponse resp =
//             PairingSuccessResponse.fromJson(payload.params!.data!);
//         pairingSettle(resp);
//         var ack = JsonRpcResult(id: Id, result: Result(resBool: true));
//         sendPairingAck(ack, session!.topic);
//         break;
//       default:
//       // case WCMethod.SESSION_REQUEST:
//       //   final param = WCSessionRequest.fromJson(request.params!.first);
//       //   log('SESSION_REQUEST $param');
//       //   _handshakeId = request.id;
//       //   _remotePeerId = param.peerId;
//       //   _remotePeerMeta = param.peerMeta;
//       //   _chainId = param.chainId;
//       //   onSessionRequest?.call(request.id, param.peerMeta);
//       //   break;
//       // case WCMethod.SESSION_UPDATE:
//       //   final param = WCSessionUpdate.fromJson(request.params!.first);
//       //   log('SESSION_UPDATE $param');
//       //   if (!param.approved) {
//       //     killSession();
//       //   }
//       //   break;
//       // case WCMethod.ETH_SIGN:
//       //   log('ETH_SIGN $request');
//       //   final params = request.params!.cast<String>();
//       //   if (params.length < 2) {
//       //     throw InvalidJsonRpcParamsException(request.id);
//       //   }

//       //   onEthSign?.call(
//       //     request.id,
//       //     WCEthereumSignMessage(
//       //       raw: params,
//       //       type: WCSignType.MESSAGE,
//       //     ),
//       //   );
//       //   break;
//       // case WCMethod.ETH_PERSONAL_SIGN:
//       //   log('ETH_PERSONAL_SIGN $request');
//       //   final params = request.params!.cast<String>();
//       //   if (params.length < 2) {
//       //     throw InvalidJsonRpcParamsException(request.id);
//       //   }

//       //   onEthSign?.call(
//       //     request.id,
//       //     WCEthereumSignMessage(
//       //       raw: params,
//       //       type: WCSignType.PERSONAL_MESSAGE,
//       //     ),
//       //   );
//       //   break;
//       // case WCMethod.ETH_SIGN_TYPE_DATA:
//       //   log('ETH_SIGN_TYPE_DATA $request');
//       //   final params = request.params!.cast<String>();
//       //   if (params.length < 2) {
//       //     throw InvalidJsonRpcParamsException(request.id);
//       //   }

//       //   onEthSign?.call(
//       //     request.id,
//       //     WCEthereumSignMessage(
//       //       raw: params,
//       //       type: WCSignType.TYPED_MESSAGE,
//       //     ),
//       //   );
//       //   break;
//       // case WCMethod.ETH_SIGN_TRANSACTION:
//       //   log('ETH_SIGN_TRANSACTION $request');
//       //   final param = WCEthereumTransaction.fromJson(request.params!.first);
//       //   onEthSignTransaction?.call(request.id, param);
//       //   break;
//       // case WCMethod.ETH_SEND_TRANSACTION:
//       //   log('ETH_SEND_TRANSACTION $request');
//       //   final param = WCEthereumTransaction.fromJson(request.params!.first);
//       //   onEthSendTransaction?.call(request.id, param);
//       //   break;

//     }
//   }

//   killSession() async {
//     //await updateSession(approved: false);
//     disconnect();
//   }

//   _resetState() {
//     _handshakeId = -1;
//     _isConnected = false;
//     _session = null;
//     _peerId = null;
//     _remotePeerId = null;
//     _remotePeerMeta = null;
//     _peerMeta = null;
//   }

//   void handleOtherRelayEvents(Map<String, dynamic> data) {
//     if (Helpers.isSubscribeEvent(data)) {
//       var resp = WakuSubscribeResponse.fromJson(data);
//       subscriptionId = resp.result!;
//       log("Received subscribe event with subscriptionId " + subscriptionId);
//     } else {
//       var resp = WakuPublishResponse.fromJson(data);
//       log("Received on handlingOtherRelay Events " + resp.result.toString());
//     }
//   }
// }
