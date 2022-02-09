class Reason {
  //int code;
  String reason;

  Reason({required this.reason});

  factory Reason.fromJson(Map<String, dynamic> json) => Reason(
        //code: json['code'] as int? ?? 0,
        reason: json['reason'] as String,
      );

  Map<String, dynamic> toJson() => {
        // 'code': code,
        'reason': reason,
      };
}
