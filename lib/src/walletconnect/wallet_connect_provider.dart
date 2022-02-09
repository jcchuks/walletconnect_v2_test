import 'dart:developer';

import 'package:app/src/walletconnect/models/app_metadata.dart';
import 'package:app/src/walletconnect/wc_client2.dart';
import 'package:flutter/material.dart';
// import 'package:wallet_connect/models/jsonrpc/json_rpc_request.dart';
// import 'package:wallet_connect/models/wc_method.dart';
// import 'package:wallet_connect/utils/constants.dart';
// import 'package:wallet_connect/wallet_connect.dart';
import 'package:uuid/uuid.dart';

class WalletConnectProvider extends ChangeNotifier {
  WalletConnectProvider() {
    init();
  }
  String projectId = "565785841a0ad653cae1d1790f90c289";
  get version => "2";
  int chainId = 1;
  String topic = '';
//wc:b0ec41e3-6250-4ce1-ad3e-45fb78aa2862@1?bridge=https%3A%2F%2F2.bridge.walletconnect.org&key=9c4ee1b70d84c57f91d810681a93c2dc00649104748a85d94fb3895e90710506
//wc:196b9223-bf66-4d33-a4f1-c231f7d8f0a4@1?bridge=https%3A%2F%2F2.bridge.walletconnect.org&key=aa5f534b1785c8ea9d266a7e45c06fe55ff87f313717d847bfc663c005c41675
//wc:df07df98-e9c6-42d8-9c4f-381499244c76@1?bridge=https%3A%2F%2F2.bridge.walletconnect.org&key=d5012dc3ed70ef9b306542f01128ff203b14bce765a0b29ed9ca456e107a241b
//wc:86d31204dae724192ae64c6a4a787a02e952678441a57f7e6b39e3478e089a38@2?controller=false&publicKey=a3736f7989ca5d10b2fce9ae5423b4dca81f2b1a6184ae6c8179871858913b5b&relay=%7B%22protocol%22%3A%22waku%22%7D

  get relayProvider => 'https://relay.walletconnect.com?projectId=$projectId';

  // get topic => sha256
  //     .convert(utf8.encode(const Uuid().v4()))
  //     .toString(); // const Uuid().v4();

  get icons => "https://nodejs.org/static/images/logo.svg";

  late WcClient wcClient;
  String peerId = Uuid().v4();
  int requestId = DateTime.now().microsecondsSinceEpoch;

  get name => "Hieros NFT View";

  get url => "https://www.thehieros.com/";

  get description => "Display your NFT collections";
  String outBandUri = '';

  bool isInitialized = false;
  bool isDialogOpen = false;
  bool isConnected = false;

  init() {
    wcClient = WcClient();
    topic = const Uuid().v4();
    wcClient
        .init(
            metadata: AppMetadata(
                name: name, description: description, url: url, icons: [icons]),
            relayProvider: relayProvider,
            topic: topic)
        .then((value) {
      isInitialized = true;
      notifyListeners();
    });
  }

  void connect() {
    if (isInitialized) {
      wcClient.connect().then((value) {
        outBandUri = value;
        isConnected = wcClient.isConnected;
        notifyListeners();
      });
    } else {
      WcException(
          type: WcErrorType.unknownOperation,
          msg: "Cannot connect with an uninitialized client");
    }
  }

  void newSession() {
    if (isConnected) {
      wcClient.proposeNewSession(blockChainIds: [BlockChainIds.etheriumMainet]);
    } else {
      WcException(
          type: WcErrorType.unknownOperation,
          msg: "Cannot create new session with an unconnected client");
    }
  }

  void disconnect() {
    if (isConnected) {
      wcClient.disconnect(topic: topic).then((value) {
        isConnected = wcClient.isConnected;
        isDialogOpen = false;
        notifyListeners();
      });
    } else {
      // WcException(
      //     type: WcErrorType.unknownOperation,
      //     msg: "Cannot disconnect an unconnected client");
    }
  }
}
