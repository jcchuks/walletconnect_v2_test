import 'package:app/src/walletconnect/chain_ids.dart';
import 'package:app/src/walletconnect/models/app_metadata.dart';
import 'package:app/src/walletconnect/wc_client2.dart';
import 'package:app/src/walletconnect/wc_errors.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WalletConnectProvider extends ChangeNotifier {
  WalletConnectProvider() {
    init();
  }
  String projectId = dotenv.env['PROJECT_ID']!;
  get version => "2";
  int chainId = 1;
  String topic = '';

  get relayProvider => 'https://relay.walletconnect.com?projectId=$projectId';

  get icons => "https://nodejs.org/static/images/logo.svg";

  late WcClient wcClient;

  get name => "Test Test";

  get url => "https://www.google.com/";

  get description => "Working Sample";
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
