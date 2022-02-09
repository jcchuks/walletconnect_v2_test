import 'package:app/src/walletconnect/models/session_signal.dart';

import 'relay.dart';
import 'session_proposed_permissions.dart';
import 'session_proposer.dart';

class SessionProposal {
  String topic;
  Relay? relay;
  SessionProposer? sessionProposer;
  SessionSignal signal;
  SessionProposedPermissions? sessionProposedPermissions;
  int ttl;

  SessionProposal({
    required this.topic,
    this.relay,
    this.sessionProposer,
    required this.signal,
    this.sessionProposedPermissions,
    required this.ttl,
  });

  factory SessionProposal.fromJson(Map<String, dynamic> json) {
    return SessionProposal(
      topic: json['topic'] as String,
      relay: json['relay'] == null
          ? null
          : Relay.fromJson(json['relay'] as Map<String, dynamic>),
      sessionProposer: json['SessionProposer'] == null
          ? null
          : SessionProposer.fromJson(
              json['SessionProposer'] as Map<String, dynamic>),
      signal: SessionSignal.fromJson(json['signal'] as Map<String, dynamic>),
      sessionProposedPermissions: json['SessionProposedPermissions'] == null
          ? null
          : SessionProposedPermissions.fromJson(
              json['SessionProposedPermissions'] as Map<String, dynamic>),
      ttl: json['ttl'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'relay': relay?.toJson(),
        'SessionProposer': sessionProposer?.toJson(),
        'signal': signal.toJson(),
        'SessionProposedPermissions': sessionProposedPermissions?.toJson(),
        'ttl': ttl,
      };
}
