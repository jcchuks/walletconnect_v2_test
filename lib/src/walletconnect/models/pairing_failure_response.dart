class PairingFailureResponse {
  String? reason;

  PairingFailureResponse({this.reason});

  factory PairingFailureResponse.fromJson(Map<String, dynamic> json) {
    return PairingFailureResponse(
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'reason': reason,
      };
}
