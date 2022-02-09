class WakuPublishResponse {
  int? id;
  String jsonrpc;
  bool? result;

  WakuPublishResponse({this.id, this.jsonrpc = '2.0', this.result});

  factory WakuPublishResponse.fromJson(Map<String, dynamic> json) {
    return WakuPublishResponse(
      id: json['id'] as int?,
      jsonrpc: json['jsonrpc'] as String? ?? '2.0',
      result: json['result'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jsonrpc': jsonrpc,
        'result': result,
      };
}
