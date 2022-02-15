class Blockchain {
  List<String> chains;

  Blockchain({required this.chains});

  factory Blockchain.fromJson(Map<String, dynamic> json) => Blockchain(
        chains: List<String>.from(json['chains'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'chains': chains,
      };
}
