class AppMetadata {
  String? name;
  String? description;
  String? url;
  List<dynamic>? icons;

  AppMetadata({this.name, this.description, this.url, this.icons});

  factory AppMetadata.fromJson(Map<String, dynamic> json) => AppMetadata(
        name: json['name'] as String?,
        description: json['description'] as String?,
        url: json['url'] as String?,
        icons: json['icons'] as List<dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'url': url,
        'icons': icons,
      };
}
