/// 発信者の共有のリンク（届ける・広める仕様書 4.3.1）。
///
/// - 共有のリンク：`https://oiboshi.perrii.app/c/{発信者 ID}`。共有のページ（公開サイトのリポジトリ（別管理）の `oiboshi/worker/`）を通る。
/// - 共有のページの「アプリで開く」：`oiboshi://c/{発信者 ID}`（同じドメインのリンクでは iOS がアプリを開かないため。tech-risks 2.30）。
///   dev のアプリは、本番のリンクを横取りしないよう `oiboshi-dev://c/{発信者 ID}` で受ける（環境構成 10）。
abstract final class ShareLink {
  static const host = 'oiboshi.perrii.app';
  static const scheme = 'oiboshi';
  static const devScheme = 'oiboshi-dev';

  /// 発信者 ID の形（データ設計書 4章）。リンクから受けた ID は、これに合うときだけ使う。
  static final _creatorId = RegExp(r'^[a-z0-9_-]{1,40}$');

  /// 誘う用の印（届ける・広める仕様書 4.3.6）。`?invite=1`。
  static const inviteParam = 'invite';

  /// [creatorId] の共有のリンク。[invite] なら、誘う用の印（`?invite=1`）を付ける。
  static Uri forCreator(String creatorId, {bool invite = false}) => Uri(
    scheme: 'https',
    host: host,
    path: '/c/$creatorId',
    queryParameters: invite ? {inviteParam: '1'} : null,
  );

  /// 告知のリンクの短い URL（`https://oiboshi.perrii.app/s/{ID}`。届ける・広める仕様書 4.4.2）。
  static Uri forShortId(String id) =>
      Uri(scheme: 'https', host: host, path: '/s/$id');

  /// 誘う用のリンクか（`invite=1` が付いている）。
  static bool isInvite(Uri uri) => uri.queryParameters[inviteParam] == '1';

  /// [url] が、[creatorId] の誘う用のリンク（`https://oiboshi.perrii.app/c/{ID}?invite=1`）か。
  /// リンク集に最初から入る誘うリンク（届ける・広める仕様書 4.6.6）を、アプリの発信者ページで出さないために使う。
  static bool isInviteLinkFor(String creatorId, String url) {
    final uri = Uri.tryParse(url.trim());
    return uri != null &&
        uri.host == host &&
        uri.path == '/c/$creatorId' &&
        isInvite(uri);
  }

  /// 共有のリンク・アプリで開くのリンクなら、発信者 ID を返す。ほかの URL なら null。
  static String? creatorIdFrom(Uri uri) {
    final List<String> segments;
    if (uri.scheme == 'https' && uri.host == host) {
      // https://oiboshi.perrii.app/c/{ID}（末尾の / も許す）
      segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    } else if (uri.scheme == scheme || uri.scheme == devScheme) {
      // oiboshi://c/{ID}：c がホスト、ID がパスになる。
      segments = [uri.host, ...uri.pathSegments.where((s) => s.isNotEmpty)];
    } else {
      return null;
    }
    if (segments.length != 2 || segments[0] != 'c') return null;
    final id = segments[1];
    return _creatorId.hasMatch(id) ? id : null;
  }

  /// 文字列（クリップボードの中身など）が共有のリンクなら、発信者 ID を返す。前後の空白は無視する。
  static String? creatorIdFromText(String? text) => fromText(text)?.creatorId;

  /// 文字列が共有のリンクなら、発信者 ID と、誘う用のリンクか（4.3.6）を返す。ほかなら null。
  static ({String creatorId, bool invite})? fromText(String? text) {
    final trimmed = text?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    final id = creatorIdFrom(uri);
    return id == null ? null : (creatorId: id, invite: isInvite(uri));
  }
}
