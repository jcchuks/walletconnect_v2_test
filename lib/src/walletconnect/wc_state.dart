import 'package:app/src/walletconnect/models/app_metadata.dart';
import 'package:app/src/walletconnect/models/pairing_failure_response.dart';
import 'package:app/src/walletconnect/models/pairing_proposal.dart';
import 'package:app/src/walletconnect/models/pairing_settled.dart';
import 'package:app/src/walletconnect/models/pairing_signal.dart';
import 'package:app/src/walletconnect/models/sequence.dart';
import 'package:app/src/walletconnect/models/session_proposal.dart';
import 'package:app/src/walletconnect/models/session_settled.dart';
import 'package:app/src/walletconnect/models/session_signal.dart';
import 'package:app/src/walletconnect/models/uri_parameters.dart';
import 'package:cryptography/cryptography.dart';

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

  //Map Settled Topics to Keypairs and settled pairings data

  Map<String, Map<SimpleKeyPair, PairingSettled>> settledPairingsMap = {};

  Map<String, Map<SimpleKeyPair, PairingSettled>> settledSessionsMap = {};

  State(
      {required this.uriParameters,
      required this.appMetadata,
      required this.pairingSignal,
      required this.keyPair});

  reset() {
    pairingSettled = PairingSettled(topic: '', sharedKey: '');
    sessionSettled = SessionSettled(topic: '');
    sessionProposal = SessionProposal(
        topic: '', signal: SessionSignal(params: Sequence(topic: '')), ttl: 0);
    pairingProposal = PairingProposal(topic: '');
    pairingFailureResponse = PairingFailureResponse();
    settledPairingsMap.clear();
    settledSessionsMap.clear();
  }
}
