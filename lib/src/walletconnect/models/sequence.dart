class Sequence {
  String topic;

  Sequence({required this.topic});

  factory Sequence.fromJson(Map<String, dynamic> json) => Sequence(
        topic: json['topic'] as String,
      );

  Map<String, dynamic> toJson() => {
        'topic': topic,
      };
}
