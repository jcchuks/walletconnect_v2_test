import 'sequence.dart';

class SessionSignal {
  String method;
  Sequence params;

  SessionSignal({this.method = 'pairing', required this.params});

  factory SessionSignal.fromJson(Map<String, dynamic> json) => SessionSignal(
        method: json['method'] as String? ?? 'pairing',
        params: Sequence.fromJson(json['topic'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'method': method,
        'topic': params.toJson(),
      };
}
