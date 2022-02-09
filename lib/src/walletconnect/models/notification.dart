import 'data.dart';

class Notification {
  String? type;
  Data? data;

  Notification({this.type, this.data});

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        type: json['type'] as String?,
        data: json['data'] == null
            ? null
            : Data.fromJson(json['data'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data?.toJson(),
      };
}
