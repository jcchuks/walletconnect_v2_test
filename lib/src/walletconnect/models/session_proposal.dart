import 'package:app/src/walletconnect/models/session_signal.dart';

import 'relay.dart';
import 'session_proposed_permissions.dart';
import 'session_proposer.dart';

class SessionProposal {
  String topic;
  Relay? relay;
  SessionProposer? proposer;
  SessionSignal signal;
  SessionProposedPermissions? permissions;
  int ttl;

  SessionProposal({
    required this.topic,
    this.relay,
    this.proposer,
    required this.signal,
    this.permissions,
    required this.ttl,
  });

  factory SessionProposal.fromJson(Map<String, dynamic> json) {
    return SessionProposal(
      topic: json['topic'] as String,
      relay: json['relay'] == null
          ? null
          : Relay.fromJson(json['relay'] as Map<String, dynamic>),
      proposer: json['proposer'] == null
          ? null
          : SessionProposer.fromJson(json['proposer'] as Map<String, dynamic>),
      signal: SessionSignal.fromJson(json['signal'] as Map<String, dynamic>),
      permissions: json['permissions'] == null
          ? null
          : SessionProposedPermissions.fromJson(
              json['permissions'] as Map<String, dynamic>),
      ttl: json['ttl'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'relay': relay?.toJson(),
        'proposer': proposer?.toJson(),
        'signal': signal.toJson(),
        'permissions': permissions?.toJson(),
        'ttl': ttl,
      };
}
