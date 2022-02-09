class PairingState {
  String? appMetadata;

  PairingState({this.appMetadata});

  factory PairingState.fromJson(Map<String, dynamic> json) => PairingState(
        appMetadata: json['AppMetadata'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'AppMetadata': appMetadata,
      };
}
