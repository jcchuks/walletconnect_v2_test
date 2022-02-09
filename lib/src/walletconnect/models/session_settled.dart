import 'relay.dart';
import 'session_participant.dart';
import 'session_permissions.dart';
import 'session_state.dart';

class SessionSettled {
  String topic;
  Relay? relay;
  String? sharedKey;
  SessionParticipant? self;
  SessionParticipant? peer;
  SessionPermissions? permissions;
  int? expiry;
  SessionState? sessionState;

  SessionSettled({
    required this.topic,
    this.relay,
    this.sharedKey,
    this.self,
    this.peer,
    this.permissions,
    this.expiry,
    this.sessionState,
  });

  factory SessionSettled.emptySession() {
    return SessionSettled(topic: '');
  }

  // factory SessionSettled.fromJson(Map<String, dynamic> json) {
  // 	return SessionSettled(
  // 		topic: json['topic'] as String?,
  // 		relay: json['relay'] == null
  // 					? null
  // 					: Relay.fromJson(json['relay'] as Map<String, dynamic>),
  // 		sharedKey: json['sharedKey'] as String?,
  // 		self: json['self'] == null
  // 					? null
  // 					: SessionParticipant.fromJson(json['self'] as Map<String, dynamic>),
  // 		peer: json['peer'] == null
  // 					? null
  // 					: SessionParticipant.fromJson(json['peer'] as Map<String, dynamic>),
  // 		permissions: json['permissions'] == null
  // 					? null
  // 					: SessionPermissions.fromJson(json['permissions'] as Map<String, dynamic>),
  // 		expiry: json['expiry'] as int?,
  // 		sessionState: json['SessionState'] == null
  // 					? null
  // 					: SessionState.fromJson(json['SessionState'] as Map<String, dynamic>),
  // 	);
  // }

  // Map<String, dynamic> toJson() => {
  // 			'topic': topic,
  // 			'relay': relay?.toJson(),
  // 			'sharedKey': sharedKey,
  // 			'self': self?.toJson(),
  // 			'SessionParticipant': peer?.toJson(),
  // 			'SessionPermissions': permissions?.toJson(),
  // 			'expiry': expiry,
  // 			'SessionState': sessionState?.toJson(),
  // 		};
}
