class Jsonrpc {
  List<dynamic>? methods;

  Jsonrpc({this.methods});

  factory Jsonrpc.fromJson(Map<String, dynamic> json) => Jsonrpc(
        methods: json['methods'] as List<dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'methods': methods,
      };
}
