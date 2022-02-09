class PairingProposerParams {
  String? uri;

  PairingProposerParams({this.uri});

  factory PairingProposerParams.fromJson(Map<String, dynamic> json) {
    return PairingProposerParams(
      uri: json['uri'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'uri': uri,
      };
}
