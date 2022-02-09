class WakuSubscribeResponse {
	int? id;
	String? jsonrpc;
	String? result;

	WakuSubscribeResponse({this.id, this.jsonrpc, this.result});

	factory WakuSubscribeResponse.fromJson(Map<String, dynamic> json) {
		return WakuSubscribeResponse(
			id: json['id'] as int?,
			jsonrpc: json['jsonrpc'] as String?,
			result: json['result'] as String?,
		);
	}



	Map<String, dynamic> toJson() => {
				'id': id,
				'jsonrpc': jsonrpc,
				'result': result,
			};
}
