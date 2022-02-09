class Blockchain {
  List<String> chains;

  Blockchain({required this.chains});

  factory Blockchain.fromJson(Map<String, dynamic> json) => Blockchain(
        chains: json['chains'] as List<String>,
      );

  Map<String, dynamic> toJson() => {
        'chains': chains,
      };
}
