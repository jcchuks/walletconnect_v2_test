//Result is a data appended to JsonRpcResult
class Result {
  String? resString;
  Map<String, dynamic>? resMap;
  bool? resBool;
  bool isBoolType = true;

  Result({this.resString, this.resBool, this.resMap, this.isBoolType = true});

  factory Result.fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    throw UnimplementedError('Result.fromJson($json) is not implemented');
  }

  // Map<String, dynamic> toJson() {
  //   return resMap ?? {};
  // }

  @override
  String toString() {
    return resString ?? '';
  }

  bool toBool() {
    return resBool ?? false;
  }
}
