import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../utils/server_time.dart';
import 'enum_name.dart';
import 'sns_service.dart';

/// 発信者。`creator_summaries` ビューの1行（`lives` を埋め込んだもの）。
class Creator {
  const Creator({
    required this.id,
    required this.name,
    this.bio = '',
    this.avatarUrl,
    this.coverUrl,
    this.linkedAccounts = const {},
    this.followerCounts = const {},
    this.xOption = false,
    this.plan = CreatorPlan.standard,
    this.live,
    this.latestPostAt,
    this.types = const [],
    this.suspended = false,
  });

  factory Creator.fromRow(Map<String, dynamic> row) {
    final live = row['lives'] as Map<String, dynamic>?;
    return Creator(
      id: row['id'] as String,
      name: row['name'] as String,
      bio: (row['bio'] as String?) ?? '',
      avatarUrl: row['avatar_url'] as String?,
      coverUrl: row['cover_url'] as String?,
      linkedAccounts: {
        for (final a
            in ((row['creator_accounts'] as List<dynamic>?) ?? const [])
                .map((r) => CreatorAccount.fromRow(r as Map<String, dynamic>))
                .nonNulls)
          a.service: a,
      },
      // この版で出さない SNS（[SnsService.offered]）の数は読まない。
      followerCounts: {
        for (final service in SnsService.offeredValues)
          if ((row['follower_counts'] as Map<String, dynamic>?)?[service.name]
              case final num count)
            service: count.toInt(),
      },
      xOption: (row['x_option'] as bool?) ?? false,
      plan: CreatorPlan.fromName(row['plan'] as String?),
      // この版で出さない SNS（[SnsService.offered]）の配信は読まない。
      live: live == null ? null : Live.fromRow(live).offeredOrNull,
      latestPostAt: parseTime(row['latest_post_at'] as String?),
      types: [
        for (final t in (row['types'] as List<dynamic>?) ?? const [])
          t as String,
      ],
      suspended: (row['suspended'] as bool?) ?? false,
    );
  }

  final String id;
  final String name;
  final String bio;
  final String? avatarUrl;

  /// ページ上部のカバー画像。
  final String? coverUrl;

  /// 連携しているアカウント（`creator_accounts`）。未確認のアカウントは、オーナーにだけ読める。
  final Map<SnsService, CreatorAccount> linkedAccounts;

  /// 確認済みのアカウント。追星に出すのは、これだけ。
  Map<SnsService, String> get accounts => {
    for (final a in linkedAccounts.values)
      if (a.verified) a.service: a.account,
  };

  /// X を取得・表示するか（`creator_summaries.x_option`）。X連携プランに加入しているか、
  /// X の連携を含むプラン（永年無料・運営・確認用）なら真。判定はサーバーの `private.creator_uses_x()` だけにある。
  final bool xOption;

  /// プランの種類（機能仕様書 4.6.6）。
  final CreatorPlan plan;

  /// SNS ごとのフォロワー数。取れていない SNS は入っていない。
  final Map<SnsService, int> followerCounts;

  /// 最後に確かめたときの配信。配信していなければ null。
  final Live? live;

  /// 最新の投稿日時。新着の判定に使う。
  final DateTime? latestPostAt;

  /// タイプ（`creator_types` の ID。3つまで）。おすすめで使う（機能仕様書 4.2.2.2）。
  final List<String> types;

  /// 運営が停止した（機能仕様書 4.6.7）か。停止中の発信者は、ファンには読めないので、オーナーにだけ真が見える。
  final bool suspended;

  /// 各SNSのフォロワー数の合計。1つも取れていなければ null。
  /// SNS ごとの数のうち、いちばん粗い丸めの桁で切り捨てる（機能仕様書 4.2.5）。
  /// 丸められた数に、細かい数を足して、正確そうに見える端数を出さないため。
  int? get totalFollowers {
    if (followerCounts.isEmpty) return null;
    final sum = followerCounts.values.reduce((a, b) => a + b);
    final unit = followerCounts.entries
        .map((e) => followerCountUnit(e.key, e.value))
        .reduce((a, b) => a > b ? a : b);
    return sum ~/ unit * unit;
  }

  /// 配信状態の確認がこれより古ければ、配信中とみなさない（サーバーの確認が止まっている）。
  static const liveStaleAfter = Duration(minutes: 3);

  /// いま配信中なら、その配信。
  Live? liveAt(DateTime now) {
    final live = this.live;
    if (live == null || now.difference(live.checkedAt) > liveStaleAfter) {
      return null;
    }
    return live;
  }

  /// 画面に出す ID（`@` 付き）。
  String get handle => '@$id';

  @visibleForTesting
  Creator copyWith({
    String? name,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    Map<SnsService, CreatorAccount>? linkedAccounts,
    List<String>? types,
  }) => Creator(
    id: id,
    name: name ?? this.name,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    linkedAccounts: linkedAccounts ?? this.linkedAccounts,
    followerCounts: followerCounts,
    xOption: xOption,
    plan: plan,
    live: live,
    latestPostAt: latestPostAt,
    types: types ?? this.types,
    suspended: suspended,
  );
}

/// 発信者の SNS アカウント。`creator_accounts` テーブルの1行。
class CreatorAccount {
  const CreatorAccount({
    required this.service,
    required this.account,
    this.verified = false,
    this.handle,
    this.profileName,
    this.profileUsername,
    this.profileImageUrl,
  });

  /// 知らない SNS と、この版で出さない SNS（[SnsService.offered]）の行なら null。
  static CreatorAccount? fromRow(Map<String, dynamic> row) {
    final service = SnsService.fromName(row['service'] as String?);
    if (service == null || !service.offered) return null;
    return CreatorAccount(
      service: service,
      account: row['account'] as String,
      verified: row['verified_at'] != null,
      handle: row['handle'] as String?,
      profileName: row['profile_name'] as String?,
      profileUsername: row['profile_username'] as String?,
      profileImageUrl: row['profile_image_url'] as String?,
    );
  }

  final SnsService service;
  final String account;

  /// 本人のアカウントだと確認済みか。
  final bool verified;

  /// ハンドル（YouTube の `@` の名前。`@` は除く）。サーバーが取って入れる。推しの検索で使う。
  final String? handle;

  /// SNS での表示名・今のユーザー名（`@` は除く）・プロフィール画像の URL。今は X だけ。
  /// サーバーが投稿の取得のついでに入れる（データ設計書 3.1.4）。まだ取れていなければ null。
  final String? profileName;
  final String? profileUsername;
  final String? profileImageUrl;
}

/// 配信中の情報。`lives` テーブルの1行。
class Live {
  const Live({
    required this.service,
    required this.title,
    required this.startedAt,
    required this.playbackUrl,
    required this.link,
    required this.checkedAt,
    this.thumbnailUrl,
    this.viewerCount,
  });

  factory Live.fromRow(Map<String, dynamic> row) => Live(
    service:
        SnsService.fromName(row['service'] as String?) ??
        SnsService.twitcasting,
    title: (row['title'] as String?) ?? '',
    startedAt: parseTime(row['started_at'] as String)!,
    playbackUrl: row['playback_url'] as String,
    link: row['link'] as String,
    checkedAt: parseTime(row['checked_at'] as String)!,
    thumbnailUrl: row['thumbnail_url'] as String?,
    viewerCount: row['viewer_count'] as int?,
  );

  final SnsService service;
  final String title;
  final DateTime startedAt;

  /// アプリ内で再生する URL。ツイキャスは HLS、YouTube・Twitch は公式プレイヤーの埋め込み URL。
  final String playbackUrl;

  /// 公式プレイヤーを WebView に埋め込んで再生するか（HLS を直接再生しないサービス）。
  bool get usesEmbed =>
      service == SnsService.youtube || service == SnsService.twitch;

  /// 配信ページの URL。
  final String link;

  /// サーバーが最後に確かめた時刻。
  final DateTime checkedAt;
  final String? thumbnailUrl;
  final int? viewerCount;

  /// この版で出す SNS（[SnsService.offered]）の配信なら自分、そうでなければ null。
  Live? get offeredOrNull => service.offered ? this : null;
}

/// SNS が返すフォロワー数の、丸めの細かさ（1なら丸めていない）。
/// YouTube の登録者数は、YouTube が上から3桁に丸めて返す（例：742,000 は千の位まで）。ほかの SNS は、丸めていない。
int followerCountUnit(SnsService service, int count) {
  if (service != SnsService.youtube) return 1;
  var unit = 1;
  for (var n = count.abs(); n >= 1000; n ~/= 10) {
    unit *= 10;
  }
  return unit;
}

/// 発信者のプランの種類（`creators.plan`、機能仕様書 2.1・4.6.6）。永年無料・運営・確認用は、運営が SQL で入れる。
/// 画面に出す名前は、View で `AppLocalizations.creatorPlanName` から引く。
enum CreatorPlan {
  standard,
  complimentary,
  admin,

  /// 確認用の発信者（運営が SQL で入れる。公開の前に消す）。
  debug;

  /// 料金がかからず、X の連携も含むか。
  bool get includesX => this != standard;

  /// サーバーに保存する名前から引く。知らない名前なら基本プラン。
  static CreatorPlan fromName(String? name) =>
      values.byNameOrNull(name) ?? standard;
}
