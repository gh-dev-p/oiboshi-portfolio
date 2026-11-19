import 'post.dart';
import 'schedule_item.dart';
import 'sns_service.dart';

/// タイムスケジュール・みんなのカレンダーの絞り込み（画面定義書 2.1.4）。Provider のキーに使うので、値で等しさを決める。
class ScheduleFilter {
  const ScheduleFilter({
    this.hiddenCreatorIds = const {},
    this.services,
    this.showPlatformless = true,
    this.showLive = true,
    this.showPosts = true,
    this.hideEmpty = false,
  });

  /// 外した推し。外した推しだけを隠し、あとからフォローした推しは出す（機能仕様書 4.5.5）。
  final Set<String> hiddenCreatorIds;

  /// 表示するプラットフォーム（SNS）。null ならすべて。
  final Set<SnsService>? services;

  /// プラットフォームのない予定（イベントの公演）を出すか。絞り込みのプラットフォームの「イベント」のチップ。
  final bool showPlatformless;
  final bool showLive;
  final bool showPosts;

  /// 選んだ日に出すものがない推しの列を出さない。
  final bool hideEmpty;

  /// [ids]（フォロー中の推し）のうち、出す推し。外していない推しがいなければ、全員を出す。
  Set<String> shownCreatorIds(Iterable<String> ids) {
    final shown = {
      for (final id in ids)
        if (!hiddenCreatorIds.contains(id)) id,
    };
    return shown.isEmpty ? ids.toSet() : shown;
  }

  /// 絞り込みが効いているか（推しを全員出していない・何かの種類を外している）。
  /// 「空いている時間を隠す」（[hideEmpty]）は数えない。[ids] はフォロー中の推し。
  /// 絞り込みのボタンを、オンの見た目にするのに使う（画面定義書（スケジュール）2.1.1、2026-11-19 本人）。
  bool isNarrowed(Iterable<String> ids) =>
      shownCreatorIds(ids).length < ids.toSet().length ||
      services != null ||
      !showPlatformless ||
      !showLive ||
      !showPosts;

  /// プラットフォームで出すか。プラットフォームのないもの（null。イベントの公演）は、「イベント」のチップで決める。
  bool includesService(SnsService? service) => service == null
      ? showPlatformless
      : (services?.contains(service) ?? true);

  /// 予定を出すか。[shownIds] は [shownCreatorIds] で出すと決めた推し。
  /// イベントの公演は、プラットフォームの「イベント」のチップだけで決める（機能仕様書 4.5.5）。
  bool showsSchedule(ScheduleItem s, Set<String> shownIds) =>
      shownIds.contains(s.creatorId) &&
      includesService(s.service) &&
      (!s.isLive || showLive);

  /// 投稿を出すか。[shownIds] は [shownCreatorIds] で出すと決めた推し。
  bool showsPost(Post p, Set<String> shownIds) =>
      shownIds.contains(p.creatorId) && includesService(p.source) && showPosts;

  ScheduleFilter copyWith({
    Set<String>? hiddenCreatorIds,
    Set<SnsService>? services,
    bool clearServices = false,
    bool? showPlatformless,
    bool? showLive,
    bool? showPosts,
    bool? hideEmpty,
  }) => ScheduleFilter(
    hiddenCreatorIds: hiddenCreatorIds ?? this.hiddenCreatorIds,
    services: clearServices ? null : services ?? this.services,
    showPlatformless: showPlatformless ?? this.showPlatformless,
    showLive: showLive ?? this.showLive,
    showPosts: showPosts ?? this.showPosts,
    hideEmpty: hideEmpty ?? this.hideEmpty,
  );

  @override
  bool operator ==(Object other) =>
      other is ScheduleFilter &&
      _sameSet(other.hiddenCreatorIds, hiddenCreatorIds) &&
      _sameSet(other.services, services) &&
      other.showPlatformless == showPlatformless &&
      other.showLive == showLive &&
      other.showPosts == showPosts &&
      other.hideEmpty == hideEmpty;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(hiddenCreatorIds),
    services == null ? null : Object.hashAllUnordered(services!),
    showPlatformless,
    showLive,
    showPosts,
    hideEmpty,
  );

  static bool _sameSet<T>(Set<T>? a, Set<T>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}
