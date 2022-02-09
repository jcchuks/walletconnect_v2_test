class Notifications {
  List<dynamic>? types;

  Notifications({this.types});

  factory Notifications.fromJson(Map<String, dynamic> json) => Notifications(
        types: json['types'] as List<dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'types': types,
      };
}
