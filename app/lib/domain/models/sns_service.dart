import '../../config/app_constants.dart';
import 'enum_name.dart';

/// 追星が連携する SNS。
/// 画面に出す名前は、View で `AppLocalizations.snsServiceName` から引く（i18n設計書 6.1）。
/// 宣言の順が、どの画面でも使う並び（画面定義書 5.1.7）。サーバーには名前で保存するので、順を変えても読み書きは変わらない。
enum SnsService {
  youtube,
  x,
  instagram,
  twitcasting,
  twitch;

  /// サーバーに保存する名前から引く。知らない名前なら null。
  static SnsService? fromName(String? name) => values.byNameOrNull(name);

  /// この版で出す SNS（並びは宣言の順）。出さない SNS は、連携と表示する内容で「準備中」にし、
  /// 取得した内容（投稿・フォロワー数・アカウント・配信中の情報・取得した配信の予約・配信の実績）もアプリで読まない。
  static final List<SnsService> offeredValues = [
    for (final s in values)
      if (s.offered) s,
  ];

  /// この版で出すか。v1.0.0 は Instagram とツイキャスを出さなかった（[instagramOffered]・[twitcastingOffered]。ツイキャスは v1.1.0 で戻した）。
  bool get offered => switch (this) {
    instagram => instagramOffered,
    twitcasting => twitcastingOffered,
    _ => true,
  };

  /// [services] に入っているものを、この enum の順（画面定義書 5.1.7）に並べる。
  static List<SnsService> ordered(Iterable<SnsService> services) => [
    for (final s in values)
      if (services.contains(s)) s,
  ];

  /// 配信の予約を取れる（配信の確認もする）サービス。
  bool get hasLive => this == twitcasting || this == youtube || this == twitch;

  /// アカウントのプロフィールページ。
  Uri profileUrl(String account) {
    final id = Uri.encodeComponent(account);
    return switch (this) {
      twitcasting => Uri.parse('https://twitcasting.tv/$id'),
      youtube => Uri.parse('https://www.youtube.com/channel/$id'),
      instagram => Uri.parse('https://www.instagram.com/$id/'),
      twitch => Uri.parse('https://www.twitch.tv/$id'),
      x => Uri.parse('https://x.com/$id'),
    };
  }
}

/// 追星に出す内容の種類（`creator_displays.content`）。
/// 画面に出す名前は、View で `AppLocalizations.displayContentName` から引く。
enum DisplayContent {
  live,
  video,
  post,
  schedule;

  static DisplayContent? fromName(String? name) => values.byNameOrNull(name);

  /// SNS ごとに選べる内容（データ設計書 3.1.9）。
  static List<DisplayContent> availableFor(SnsService service) =>
      switch (service) {
        SnsService.youtube => const [live, video, schedule],
        SnsService.twitcasting => const [live, schedule],
        SnsService.twitch => const [live, schedule],
        SnsService.instagram => const [post],
        SnsService.x => const [post],
      };
}
