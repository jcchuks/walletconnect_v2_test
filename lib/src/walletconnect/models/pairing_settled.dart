import 'pairing_participant.dart';
import 'pairing_permissions.dart';
import 'pairing_state.dart';
import 'relay.dart';

class PairingSettled {
  String topic;
  Relay? relay;
  String sharedKey;
  PairingParticipant? self;
  PairingParticipant? peer;
  PairingPermissions? permissions;
  int? expiry;
  PairingState? state;

  PairingSettled({
    required this.topic,
    this.relay,
    required this.sharedKey,
    this.self,
    this.peer,
    this.permissions,
    this.expiry,
    this.state,
  });

  // factory PairingSettled.fromJson(Map<String, dynamic> json) {
  //   return PairingSettled(
  //     topic: json['topic'] as String?,
  //     relay: json['relay'] == null
  //         ? null
  //         : Relay.fromJson(json['relay'] as Map<String, dynamic>),
  //     sharedKey: json['sharedKey'] as String?,
  //     self: json['self'] == null
  //         ? null
  //         : PairingParticipant.fromJson(json['self'] as Map<String, dynamic>),
  //     peer: json['peer'] == null
  //         ? null
  //         : PairingParticipant.fromJson(json['peer'] as Map<String, dynamic>),
  //     permissions: json['permissions'] == null
  //         ? null
  //         : PairingPermissions.fromJson(
  //             json['permissions'] as Map<String, dynamic>),
  //     expiry: json['expiry'] as int?,
  //     state: json['state'] == null
  //         ? null
  //         : PairingState.fromJson(json['state'] as Map<String, dynamic>),
  //   );
  // }

  // Map<String, dynamic> toJson() => {
  //       'topic': topic,
  //       'relay': relay?.toJson(),
  //       'sharedKey': sharedKey,
  //       'self': self?.toJson(),
  //       'PairingParticipant': peer?.toJson(),
  //       'PairingPermissions': permissions?.toJson(),
  //       'expiry': expiry,
  //       'PairingState': state?.toJson(),
  //     };
}
