import 'pairing_proposer_params.dart';

class PairingSignal {
  String type;
  PairingProposerParams? pairingProposerParams;

  PairingSignal({this.type = 'uri', this.pairingProposerParams});

  factory PairingSignal.fromJson(Map<String, dynamic> json) => PairingSignal(
        type: json['type'] as String? ?? 'uri',
        pairingProposerParams: json['PairingProposerParams'] == null
            ? null
            : PairingProposerParams.fromJson(
                json['PairingProposerParams'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'PairingProposerParams': pairingProposerParams?.toJson(),
      };
}
