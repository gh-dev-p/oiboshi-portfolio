/// 週間の告知画像のテンプレ（届ける・広める仕様書 4.4.1）。一覧はサーバー（Edge Functions の `announce-image`）が返す。
class AnnounceTemplate {
  const AnnounceTemplate({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    this.isDefault = false,
  });

  factory AnnounceTemplate.fromJson(Map<String, dynamic> json) =>
      AnnounceTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        thumbnailUrl: json['thumbnail_url'] as String,
        isDefault: json['default'] == true,
      );

  /// サーバーの既定のテンプレ。一覧が取れないときも、これで作る（知らない ID はサーバーが既定にする）。
  static const defaultId = 'spotlight';

  final String id;
  final String name;
  final String thumbnailUrl;

  /// サーバーの既定のテンプレか。
  final bool isDefault;
}
