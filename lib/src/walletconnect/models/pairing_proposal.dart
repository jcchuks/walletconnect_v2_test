import 'pairing_proposed_permissions.dart';
import 'pairing_proposer.dart';
import 'pairing_signal.dart';
import 'relay.dart';

class PairingProposal {
  String topic;
  Relay? relay;
  PairingProposer? pairingProposer;
  PairingSignal? pairingSignal;
  PairingProposedPermissions? pairingProposedPermissions;
  int ttl;

  PairingProposal({
    required this.topic,
    this.relay,
    this.pairingProposer,
    this.pairingSignal,
    this.pairingProposedPermissions,
    this.ttl = 8640,
  });

  factory PairingProposal.fromJson(Map<String, dynamic> json) {
    return PairingProposal(
      topic: json['topic'] as String,
      relay: json['relay'] == null
          ? null
          : Relay.fromJson(json['relay'] as Map<String, dynamic>),
      pairingProposer: json['PairingProposer'] == null
          ? null
          : PairingProposer.fromJson(
              json['PairingProposer'] as Map<String, dynamic>),
      pairingSignal: json['PairingSignal'] == null
          ? null
          : PairingSignal.fromJson(
              json['PairingSignal'] as Map<String, dynamic>),
      pairingProposedPermissions: json['PairingProposedPermissions'] == null
          ? null
          : PairingProposedPermissions.fromJson(
              json['PairingProposedPermissions'] as Map<String, dynamic>),
      ttl: json['ttl'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'relay': relay?.toJson(),
        'PairingProposer': pairingProposer?.toJson(),
        'PairingSignal': pairingSignal?.toJson(),
        'PairingProposedPermissions': pairingProposedPermissions?.toJson(),
        'ttl': ttl,
      };
}
