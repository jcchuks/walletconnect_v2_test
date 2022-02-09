class PairingParticipant {
  String? publicKey;

  PairingParticipant({this.publicKey});

  factory PairingParticipant.fromJson(Map<String, dynamic> json) {
    return PairingParticipant(
      publicKey: json['publicKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
      };
}
