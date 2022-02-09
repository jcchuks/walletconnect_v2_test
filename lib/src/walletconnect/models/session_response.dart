import 'session_state.dart';

class SessionResponse {
  SessionState? sessionState;

  SessionResponse({this.sessionState});

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    return SessionResponse(
      sessionState: json['SessionState'] == null
          ? null
          : SessionState.fromJson(json['SessionState'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'SessionState': sessionState?.toJson(),
      };
}
