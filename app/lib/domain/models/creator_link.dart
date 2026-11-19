import '../../utils/text_limits.dart';
import 'app_error.dart';
import 'sns_service.dart';

/// リンク集のリンク（届ける・広める仕様書 4.6、データ設計書 3.1.32）。
class CreatorLink {
  const CreatorLink({
    required this.id,
    required this.title,
    required this.url,
    this.clickCount,
  });

  /// 表（`creator_links`）・関数（`owned_creator_links`）の行から作る。
  factory CreatorLink.fromRow(Map<String, dynamic> row) => CreatorLink(
    id: row['id'] as String,
    title: row['title'] as String,
    url: row['url'] as String,
    clickCount: (row['click_count'] as num?)?.toInt(),
  );

  final String id;
  final String title;
  final String url;

  /// 押された回数。オーナーが読んだときだけある（ファンには見せない）。
  final int? clickCount;

  /// 行き先のドメイン。読めなければ URL のまま。
  String get host => Uri.tryParse(url)?.host ?? url;
}

/// リンク集の決まり（届ける・広める仕様書 4.6.1）。
/// SNS（[SnsService]）のほかに、リンクのボタンに公式アイコンを付けるサービス（届ける・広める仕様書 4.6.7。2026-11-19 本人）。
/// 素材は各社の配布物から取り込んだ（`assets/brands/`。tech-risks.md 2.21）。
/// LINE は、決まりの最小の大きさ（スマホで 40px）をボタンのアイコンで満たせないので、入れない。
enum LinkBrand {
  spotify,
  discord;

  /// 素材のファイル名（`assets/brands/` の中。公開のページは `/assets/brand-{name}.png`）。
  String get asset => '$name.png';
}

abstract final class CreatorLinkRules {
  /// [url] の行き先が、SNS 以外の公式アイコンを付けるサービス（[LinkBrand]）なら、それを返す。ウェブでも同じ。
  /// 公開のページ（公開サイトのリポジトリ（別管理） の Worker）と同じ対応表。
  static LinkBrand? brandFor(String url) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase();
    if (host == null || host.isEmpty) return null;
    bool on(String domain) => host == domain || host.endsWith('.$domain');
    if (on('spotify.com')) return LinkBrand.spotify;
    if (on('discord.com') || on('discord.gg') || on('discordapp.com')) {
      return LinkBrand.discord;
    }
    return null;
  }

  /// リンクの行き先（[url] のドメイン）から、ボタンの左に付ける公式アイコンのサービスを決める（届ける・広める仕様書 4.6.7）。
  /// ツイキャスは、アプリでもウェブでも付ける（2026-11-19 本人）。
  /// 分からない行き先は null（ふつうのリンクの印）。[web] なら、公開のページ（ウェブ）で使えるものだけ
  /// （Twitch は商標のポリシーで第三者のウェブサイトでのロゴを認めないので、ウェブでは付けない。tech-risks.md 2.21）。
  /// 公開のページ（公開サイトのリポジトリ（別管理） の `oiboshi/worker/`）と同じ対応表。
  static SnsService? iconServiceFor(String url, {bool web = false}) {
    final host = Uri.tryParse(url.trim())?.host.toLowerCase();
    if (host == null || host.isEmpty) return null;
    bool on(String domain) => host == domain || host.endsWith('.$domain');
    if (on('youtube.com') || host == 'youtu.be') return SnsService.youtube;
    if (on('x.com') || on('twitter.com')) return SnsService.x;
    if (on('instagram.com')) return SnsService.instagram;
    if (on('twitcasting.tv')) return SnsService.twitcasting;
    if (!web && on('twitch.tv')) return SnsService.twitch;
    return null;
  }

  /// リンク集のページ（公開のページ・アプリの見本）にボタンで出すリンク（届ける・広める仕様書 4.6.7）。
  /// 全部、登録した順に出す。https のものだけ。SNS のアイコンの列は、v1.1.0 では出さない（次の版で考える。2026-11-19 本人）。
  /// 公開のページ（公開サイトのリポジトリ（別管理） の `oiboshi/worker/` の `pageLinks`）と同じ決まり。どちらも同じ表のテストで確かめる
  /// （`app/test/fixtures/links_page_cases.json` と、公開サイトのリポジトリ（別管理） の `oiboshi/worker/links_page_cases.json`）。
  static List<CreatorLink> pageLinks(List<CreatorLink> links) => [
    for (final l in links)
      if (isHttpsUrl(l.url)) l,
  ];

  /// 大文字と小文字・末尾の / の違いを見ずに、URL を比べる形にする（公開のページの normUrl と同じ）。
  static String _normUrl(String u) {
    final t = u.trim().toLowerCase();
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  /// [url] が、つないだ SNS（[accounts]）のどれかのアカウントのページか（届ける・広める仕様書 4.6.2）。
  /// 自動で入れた SNS のリンク（4.6.5）は、この形になる。大文字と小文字・末尾の / の違いは見ない。
  /// アプリの発信者ページでは、SNS ごとのフォロワー数の所から開けるので、ボタンを出さない（2026-11-19 本人）。
  static bool isSnsProfileLink(Map<SnsService, String> accounts, String url) {
    final target = _normUrl(url);
    return accounts.entries.any(
      (e) => _normUrl(e.key.profileUrl(e.value).toString()) == target,
    );
  }

  /// 1つの発信者に置けるリンクの数。
  static const maxLinks = 10;

  /// 題名の長さ（見た目の1文字）。
  static const maxTitleLength = 30;

  /// URL の長さ。
  static const maxUrlLength = 2000;

  /// 題名として受け付けるか（前後の空白を除いて、1〜30文字）。
  static bool isValidTitle(String title) {
    final length = graphemeLength(title.trim());
    return length >= 1 && length <= maxTitleLength;
  }

  /// URL として受け付けるか（`https://` で始まり、ホストがある。2000文字まで）。
  /// 短縮 URL は、サーバーが断る（一覧はデータベースにある）。
  static bool isValidUrl(String url) {
    final u = url.trim();
    return u.length <= maxUrlLength && isHttpsUrl(u);
  }
}

/// リンク集の保存で、サーバーが断った理由。
enum CreatorLinkError {
  /// 短縮 URL のドメイン。
  shortUrl,

  /// 10件を超える。
  limit,

  /// ほかの端末で足した・消したので、並びが古い。
  stale,
}

/// リンク集の保存を、サーバーが決まりで断った。[AppException] の一種なので、`mapErrors` を素通りする。
class CreatorLinkException extends AppException {
  const CreatorLinkException(this.error) : super(AppErrorKind.unknown);

  final CreatorLinkError error;

  @override
  String toString() => 'CreatorLinkException($error)';
}
