class SessionFailureResponse {
  String? reason;

  SessionFailureResponse({this.reason});

  factory SessionFailureResponse.fromJson(Map<String, dynamic> json) {
    return SessionFailureResponse(
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'reason': reason,
      };
}
