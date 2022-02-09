import 'relay.dart';
import 'session_participant.dart';
import 'session_state.dart';

class SessionSuccessResponse {
  String topic;
  Relay? relay;
  SessionParticipant? sessionParticipant;
  int? expiry;
  SessionState? sessionState;

  SessionSuccessResponse({
    required this.topic,
    this.relay,
    this.sessionParticipant,
    this.expiry,
    this.sessionState,
  });

  factory SessionSuccessResponse.fromJson(Map<String, dynamic> json) {
    return SessionSuccessResponse(
      topic: json['topic'] as String,
      relay: json['relay'] == null
          ? null
          : Relay.fromJson(json['relay'] as Map<String, dynamic>),
      sessionParticipant: json['SessionParticipant'] == null
          ? null
          : SessionParticipant.fromJson(
              json['SessionParticipant'] as Map<String, dynamic>),
      expiry: json['expiry'] as int?,
      sessionState: json['SessionState'] == null
          ? null
          : SessionState.fromJson(json['SessionState'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'relay': relay?.toJson(),
        'SessionParticipant': sessionParticipant?.toJson(),
        'expiry': expiry,
        'SessionState': sessionState?.toJson(),
      };
}
