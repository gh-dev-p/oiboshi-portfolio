import '../../utils/server_time.dart';

/// フォロー中の推し。`follows` テーブルの1行。
class Follow {
  const Follow({
    required this.creatorId,
    required this.followedAt,
    this.lastSeenAt,
    this.coverUrl,
    this.showOwnCover = true,
    this.notify = true,
  });

  factory Follow.fromRow(Map<String, dynamic> row) => Follow(
    creatorId: row['creator_id'] as String,
    followedAt: parseTime(row['followed_at'] as String)!,
    lastSeenAt: parseTime(row['last_seen_at'] as String?),
    coverUrl: row['cover_url'] as String?,
    showOwnCover: (row['show_own_cover'] as bool?) ?? true,
    notify: (row['notify'] as bool?) ?? true,
  );

  final String creatorId;
  final DateTime followedAt;

  /// 最後にその推しのページを開いた時刻。
  final DateTime? lastSeenAt;

  /// 自分で選んだカバー画像。なければ発信者のカバーを出す。
  final String? coverUrl;

  /// カバーで、自分の写真（裏）を出しているか。偽なら、発信者のカバー（表）。自分の写真がなければ使わない。
  final bool showOwnCover;

  /// この推しの配信開始の通知を受け取るか。
  final bool notify;

  Follow copyWith({
    DateTime? lastSeenAt,
    bool clearCover = false,
    bool? showOwnCover,
  }) => Follow(
    creatorId: creatorId,
    followedAt: followedAt,
    lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    coverUrl: clearCover ? null : coverUrl,
    showOwnCover: showOwnCover ?? this.showOwnCover,
    notify: notify,
  );

  /// これより古い投稿は、見ていなくても新着にしない（新着がたまり続けないように）。
  static const newWindow = Duration(days: 3);

  /// 新着の基準になる時刻（最後に見た時刻。見ていなければフォローした時刻）。
  DateTime get seenAt => lastSeenAt ?? followedAt;

  /// [postedAt] の投稿が新着か。
  bool isNew(DateTime postedAt, {required DateTime now}) =>
      isNewSince(postedAt, seenAt: seenAt, now: now);
}

/// [seenAt] より新しく、[Follow.newWindow] 以内の投稿を新着とする。
bool isNewSince(
  DateTime postedAt, {
  required DateTime seenAt,
  required DateTime now,
}) {
  final windowStart = now.subtract(Follow.newWindow);
  return postedAt.isAfter(seenAt.isAfter(windowStart) ? seenAt : windowStart);
}
