class Error {
  int? code;
  String? message;

  Error({this.code, this.message});

  factory Error.fromJson(Map<String, dynamic> json) => Error(
        code: json['code'] as int?,
        message: json['message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };
}
