enum WcErrorType { emptyValue, invalidValue, unknownOperation }

class WcException implements Exception {
  final WcErrorType type;
  final String? msg;

  WcException({required this.type, this.msg});

  @override
  String toString() => "WcException.$type: $msg";
}
