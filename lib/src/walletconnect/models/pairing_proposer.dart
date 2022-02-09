class PairingProposer {
  String publicKey;
  bool controller;

  PairingProposer({required this.publicKey, required this.controller});

  factory PairingProposer.fromJson(Map<String, dynamic> json) {
    return PairingProposer(
      publicKey: json['publicKey'] as String,
      controller: json['controller'] as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'publicKey': publicKey,
        'controller': controller,
      };
}
