import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/oshi.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../domain/models/sns_service.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/playback_provider.dart';
import '../../core/view_models/post_shuffle_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../core/view_models/removed_posts_provider.dart';
import '../../oshi/view_models/oshi_providers.dart';
import '../../schedule/view_models/schedule_providers.dart';
import '../../../utils/formatters.dart';

/// ホームに出すもの。
class HomeState {
  const HomeState({
    required this.oshis,
    required this.upcoming,
    required this.events,
    required this.posts,
    required this.exhausted,
    this.upcomingMore = 0,
    this.eventsMore = 0,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  /// フォロー中の推し（配信中、新着あり、それ以外の順）。
  final List<Oshi> oshis;

  /// 今日のこれからの予定（時刻順。イベントを除く。件数は [upcomingScheduleCount] まで）。
  final List<ScheduleItem> upcoming;

  /// これからのイベント（日付順。開催中を含む。件数は [upcomingEventCount] まで）。
  final List<ScheduleItem> events;

  /// 「次の予定」に出しきれない予定の件数（「ほか N 件」の N）。
  final int upcomingMore;

  /// 「イベント」に出しきれないイベントの件数（「ほか N 件」の N）。
  final int eventsMore;

  /// 全体タイムライン（新しい順）。
  final List<Post> posts;

  /// これより古い投稿は、もうない。
  final bool exhausted;

  /// 続きを読んでいるか。
  final bool loadingMore;

  /// 続きを読めなかったか。読めなかったら、下までスクロールしても読み直さず、「再試行」を待つ。
  final bool loadMoreFailed;

  HomeState copyWith({
    List<Post>? posts,
    bool? exhausted,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => HomeState(
    oshis: oshis,
    upcoming: upcoming,
    events: events,
    upcomingMore: upcomingMore,
    eventsMore: eventsMore,
    posts: posts ?? this.posts,
    exhausted: exhausted ?? this.exhausted,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

/// ホーム（画面定義書 2.2）。推しの行、次の予定、イベント、全体タイムライン。
/// 1分ごとに読み直し、下までスクロールすると 50 件ずつ続きを読む（過去 90 日まで。機能仕様書 4.4.3）。
///
/// 読み込んだ投稿と続きの位置は、Notifier のフィールドに持つ。Riverpod 3 は、Provider を作り直しても
/// Notifier を作り直さない（3.0.0-dev.16 で元に戻った）ので、1分ごとの読み直しでも消えない。
class HomeViewModel extends AsyncNotifier<HomeState> {
  /// 読み直しても消えないように、読み込んだ投稿をためておく。
  final Map<String, Post> _loaded = {};

  /// 前に読んだときの推し。推しを足したかを見分ける。
  Set<String> _ids = const {};

  /// 続きを読む位置（サーバーの並びで、読み込んだいちばん古い投稿）。
  Post? _cursor;

  /// これより古い投稿は、もうない。
  bool _exhausted = false;

  @override
  Future<HomeState> build() async {
    final now = ref.read(clockProvider)();
    final oshis = await ref.watch(oshisProvider.future);
    final upcoming = oshis.isEmpty
        ? const <ScheduleItem>[]
        : await ref.watch(upcomingSchedulesProvider.future);
    final events = oshis.isEmpty
        ? const <ScheduleItem>[]
        : await ref.watch(upcomingEventsProvider.future);
    final ids = [for (final o in oshis) o.id];
    // 追星から投稿を消したら、読み直し、続きで読んだ投稿からも外す（機能仕様書 4.4.4）。
    final removed = ref.watch(removedPostsProvider);
    refreshPeriodically(ref);
    final page = ids.isEmpty
        ? const <Post>[]
        : await ref
              .read(postRepositoryProvider)
              .fetchTimeline(ids, since: now.subtract(timelineWithin));
    _loaded.removeWhere((id, _) => removed.contains(id));
    _mergeLatest(page, ids.toSet());
    _liveVideoIds = {
      for (final o in oshis)
        if (o.creator.liveAt(now) case final live?)
          if (live.service == SnsService.youtube)
            ?Uri.tryParse(live.playbackUrl)?.pathSegments.lastOrNull,
    };
    // 「次の予定」は、次の予定（本日中）。今日のこれからの予定だけ（明日より先は、スケジュールのタブで見る）。
    final schedules = upcoming
        .where((s) => !s.isEvent && isSameDay(s.startsAt.toLocal(), now))
        .toList();
    return HomeState(
      oshis: Oshi.byStatus(oshis, now),
      upcoming: schedules.take(upcomingScheduleCount).toList(),
      events: events.take(upcomingEventCount).toList(),
      upcomingMore: _rest(schedules.length, upcomingScheduleCount),
      eventsMore: _rest(events.length, upcomingEventCount),
      posts: _timeline(now),
      exhausted: _exhausted,
    );
  }

  /// 配信中の YouTube の配信枠（RSS に動画として入る）の動画 ID。全体タイムラインには出さない（機能仕様書 4.3.4）。
  Set<String> _liveVideoIds = const {};

  /// [count] 件のうち、[shown] 件を出したときの残りの件数。
  static int _rest(int count, int shown) => count > shown ? count - shown : 0;

  /// 読み直した最新のページを、読み込んだ投稿に混ぜる。終端は、このページと推しから決め直す。
  void _mergeLatest(List<Post> page, Set<String> ids) {
    final added = !_ids.containsAll(ids);
    _ids = ids;
    final full = page.length >= timelineLimit;
    // 前に読んだ投稿とつながらない（読み直しのあいだに 1 ページを超えて増えた）。
    final gap =
        full &&
        _loaded.isNotEmpty &&
        !page.any((p) => _loaded.containsKey(p.id));
    if (!full || added || gap) {
      // ページに収まりきった、推しを足した、間があいた：続きを捨てて、このページから出し直す。
      _loaded.clear();
      _cursor = page.isEmpty ? null : page.last;
      _exhausted = !full;
    } else {
      _loaded.removeWhere((_, p) => !ids.contains(p.creatorId));
      // このページの範囲は、このページに替える（消された投稿を残さない）。
      final edge = page.last.postedAt;
      _loaded.removeWhere((_, p) => p.postedAt.isAfter(edge));
      _cursor ??= page.last;
    }
    for (final p in page) {
      _loaded[p.id] = p;
    }
  }

  List<Post> _timeline(DateTime now) {
    final since = now.subtract(timelineWithin);
    return sortNewestFirst(
      _loaded.values.where(
        (p) =>
            !p.postedAt.isBefore(since) &&
            !_liveVideoIds.contains(p.youtubeVideoId),
      ),
    );
  }

  /// 読み込んだいちばん古い投稿の次から、1ページ足す。前に読めなかったなら、[retryLoadMore] を待つ。
  Future<void> loadMore() async {
    if (state.value?.loadMoreFailed ?? false) return;
    await _loadMore();
  }

  /// 続きを読めなかったときの「再試行」。
  Future<void> retryLoadMore() => _loadMore();

  Future<void> _loadMore() async {
    final current = state.value;
    final cursor = _cursor;
    if (current == null || current.loadingMore || current.exhausted) return;
    if (cursor == null) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final older = await ref
          .read(postRepositoryProvider)
          .fetchTimeline(
            [for (final o in current.oshis) o.id],
            olderThan: cursor,
            since: ref.read(clockProvider)().subtract(timelineWithin),
          );
      if (!ref.mounted) return;
      // 読んでいるあいだに読み直して出し直したら、この続きは捨てる（間があくため）。
      if (!identical(_cursor, cursor)) return;
      for (final p in older) {
        _loaded[p.id] = p;
      }
      if (older.isNotEmpty) _cursor = older.last;
      _exhausted = older.length < timelineLimit;
      state = AsyncData(
        (state.value ?? current).copyWith(
          posts: _timeline(ref.read(clockProvider)()),
          exhausted: _exhausted,
          loadingMore: false,
        ),
      );
    } catch (_) {
      // 読めなかったら、印を止めて「再試行」を出す。
      if (ref.mounted) {
        state = AsyncData(
          (state.value ?? current).copyWith(
            loadingMore: false,
            loadMoreFailed: true,
          ),
        );
      }
    }
  }

  /// フォロー中の推しの YouTube の動画を読み、固定ビューアでランダムに流す（試作）。
  /// 追星から消した動画、生配信（配信中・配信予定）の枠、これから公開する動画は流さない（機能仕様書 4.3.5.1）。
  /// 生配信かは、サービスではなく中身で決める（[Post.isLiveContent]。終わった配信のアーカイブは流す）。
  /// 配信に切り替える前にランダム再生を流していたら、新しくシャッフルせず、同じ順番の同じ動画を同じ位置から続ける
  /// （止めていたら止めたまま）。その動画が、追星から消した・推しでなくなったなどで流せなければ、シャッフルし直す。
  Future<ShuffleStart> startShuffle() async {
    try {
      final playback = ref.read(playbackProvider.notifier);
      if (playback.suspendedShuffle != null) {
        final oshis = await ref.read(oshisProvider.future);
        if (!ref.mounted) return ShuffleStart.failed;
        final removed = ref.read(removedPostsProvider);
        if (playback.resumeSuspendedShuffle(
          canPlay: (post) =>
              !removed.contains(post.id) &&
              oshis.any((o) => o.id == post.creatorId),
        )) {
          return ShuffleStart.started;
        }
      }
      final shuffle = await _loadShuffle();
      if (shuffle == null) return ShuffleStart.failed;
      if (shuffle.order.isEmpty) return ShuffleStart.empty;
      ref
          .read(playbackProvider.notifier)
          .playShuffle(shuffle.order, shuffle.authors);
      return ShuffleStart.started;
    } catch (_) {
      return ShuffleStart.failed;
    }
  }

  /// 固定ビューアで最後に流していた動画を、[start] の位置から、ランダム再生として流す（機能仕様書 4.3.5）。
  /// その動画が、いまランダム再生で流せる動画になければ（追星から消した・推しでなくなったなど）、
  /// 何も流さずに偽を返す。読めなかったときも偽。
  Future<bool> resumeVideo(String postId, Duration start) async {
    try {
      final shuffle = await _loadShuffle();
      if (shuffle == null) return false;
      return ref
          .read(playbackProvider.notifier)
          .resumeShuffle(shuffle.order, shuffle.authors, postId, start);
    } catch (_) {
      return false;
    }
  }

  /// ランダム再生の順番と推しを読む。読んでいる間に破棄されたら null。
  Future<({PostShuffle order, Map<String, Creator> authors})?>
  _loadShuffle() async {
    final oshis = await ref.read(oshisProvider.future);
    final videos = oshis.isEmpty
        ? const <Post>[]
        : await ref.read(postRepositoryProvider).fetchYoutubeVideos([
            for (final o in oshis) o.id,
          ]);
    if (!ref.mounted) return null;
    final removed = ref.read(removedPostsProvider);
    final now = ref.read(clockProvider)();
    return (
      order: PostShuffle(
        videos.where(
          (p) =>
              !removed.contains(p.id) &&
              !p.isLiveContent &&
              !_liveVideoIds.contains(p.youtubeVideoId) &&
              !p.postedAt.isAfter(now),
        ),
      ),
      authors: {for (final o in oshis) o.id: o.creator},
    );
  }

  /// 読み直す（引き下げ、「再試行」、「もう一度試す」）。
  Future<void> refresh() => reloadFrom(
    ref,
    [authSessionProvider, followsProvider],
    awaiting: () {
      ref.invalidateSelf();
      return future;
    },
  );
}

final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

/// ランダム再生を始めた結果。
enum ShuffleStart {
  /// 始めた。
  started,

  /// 流せる動画がない。
  empty,

  /// 読めなかった。
  failed,
}
