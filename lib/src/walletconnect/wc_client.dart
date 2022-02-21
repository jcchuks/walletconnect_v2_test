import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:app/src/walletconnect/chain_ids.dart';
import 'package:app/src/walletconnect/helpers.dart';
import 'package:app/src/walletconnect/models/app_metadata.dart';
import 'package:app/src/walletconnect/models/blockchain.dart';
import 'package:app/src/walletconnect/models/jsonrpc.dart';
import 'package:app/src/walletconnect/models/pairing_proposer_params.dart';
import 'package:app/src/walletconnect/models/pairing_signal.dart';
import 'package:app/src/walletconnect/models/reason.dart';
import 'package:app/src/walletconnect/models/sequence.dart';
import 'package:app/src/walletconnect/models/session_proposal.dart';
import 'package:app/src/walletconnect/models/session_proposed_permissions.dart';
import 'package:app/src/walletconnect/models/session_proposer.dart';
import 'package:app/src/walletconnect/models/session_signal.dart';
import 'package:app/src/walletconnect/models/uri_parameters.dart';
import 'package:app/src/walletconnect/wc_core.dart';
import 'package:app/src/walletconnect/wc_crypto2.dart';
import 'package:app/src/walletconnect/wc_state.dart';
import 'package:convert/convert.dart';
import 'package:cryptography/cryptography.dart';
import 'package:web3dart/crypto.dart';

class CAIP {
  static String caipHandshake = "caip_handshake";
  static String caipRequest = "caip_request";
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
    var topicBytes = Uint8List.fromList(base64Decode(topic).toList());
    var topicSha = await WcCrypto2.getSha256(data: topicBytes);

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

  bool get isConnected => core.isConnected;

  proposeNewSession({
    required List<BlockchainId> blockChainIds,
  }) {
    List<String> chains = [];
    List<String> chainMethods = [];
    for (var chain in blockChainIds) {
      chains.add(chain.name);
      chainMethods.addAll(BlockChainIds.getChainMethods(chain: chain));
    }

    State state = core.state;
    var permissions = SessionProposedPermissions(
        blockchain: Blockchain(chains: chains),
        jsonrpc: Jsonrpc(methods: chainMethods));
    var sessionProposal = SessionProposal(
        topic: state.pairingSettled.topic,
        relay: state.pairingSettled.relay,
        permissions: permissions,
        proposer: SessionProposer(
            publicKey: state.pairingSettled.self!
                .publicKey!, //should throw error if not exists
            controller: state.uriParameters.controller,
            metadata: state.appMetadata),
        signal:
            SessionSignal(params: Sequence(topic: state.pairingSettled.topic)),
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
    var topicBytes = Uint8List.fromList(base64Decode(topic).toList());
    var topicSha = await WcCrypto2.getSha256(data: topicBytes);
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
