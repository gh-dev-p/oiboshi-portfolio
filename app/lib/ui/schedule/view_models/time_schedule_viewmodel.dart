import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/service_providers.dart';
import '../../../domain/models/oshi.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/schedule_filter.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../utils/formatters.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../core/view_models/removed_posts_provider.dart';
import '../../oshi/view_models/oshi_providers.dart';
import 'schedule_providers.dart';

/// タイムスケジュールの、1日ぶんのデータ。
class TimeScheduleData {
  const TimeScheduleData({
    required this.day,
    required this.allOshis,
    required this.oshis,
    required this.schedules,
    required this.posts,
  });

  /// このデータの日。日を切り替えて読み込むあいだは、選んだ日と違う（前の日のデータを出しておく）。
  final DateTime day;

  /// フォロー中の推し全員（絞り込みのシートで使う）。
  final List<Oshi> allOshis;

  /// 列に出す推し（絞り込み後）。
  final List<Oshi> oshis;

  /// 選んだ日に重なる予定（絞り込み後）。
  final List<ScheduleItem> schedules;

  /// 選んだ日の投稿（絞り込み後）。
  final List<Post> posts;
}

/// 選んだ日・絞り込みと、その日のデータ。拡大・縮小は、データを読み直さないように、表の View が持つ。
class TimeScheduleState {
  const TimeScheduleState({
    required this.day,
    this.filter = const ScheduleFilter(),
    this.result = const AsyncLoading(),
    this.data,
  });

  final DateTime day;
  final ScheduleFilter filter;

  /// 選んだ日と絞り込みの、読み込みの結果。日や絞り込みを切り替えると、読み込み中に戻る。
  final AsyncValue<TimeScheduleData> result;

  /// 出すデータ。日や絞り込みを切り替えて読み込むあいだと、読み直しに失敗したときは、前の値を保つ。
  /// まだ一度も読めていなければ null。
  final TimeScheduleData? data;

  /// 週の始まり（日曜）。
  DateTime get weekStart => day.subtract(Duration(days: day.weekday % 7));

  TimeScheduleState copyWith({
    DateTime? day,
    ScheduleFilter? filter,
    AsyncValue<TimeScheduleData>? result,
  }) => TimeScheduleState(
    day: day ?? this.day,
    filter: filter ?? this.filter,
    result: result ?? this.result,
    data: result?.value ?? data,
  );
}

/// タイムスケジュール（画面定義書 2.1.1）の操作（日付・絞り込み・読み直し）。
/// 選んだ日と絞り込みに合わせて、1日ぶんのデータを読み、state に載せる。
class TimeScheduleViewModel extends Notifier<TimeScheduleState> {
  ProviderSubscription<AsyncValue<TimeScheduleData>>? _subscription;
  _TimeScheduleQuery? _query;

  @override
  TimeScheduleState build() {
    ref.onDispose(() => _subscription?.close());
    final initial = TimeScheduleState(day: dateOnly(ref.read(clockProvider)()));
    return initial.copyWith(result: _watchData(initial));
  }

  void selectDay(DateTime day) => _select(state.copyWith(day: dateOnly(day)));

  /// 今日（時計の日）。
  DateTime get today => dateOnly(ref.read(clockProvider)());

  void setFilter(ScheduleFilter filter) =>
      _select(state.copyWith(filter: filter));

  /// 読み直す（「再試行」、「もう一度試す」）。
  Future<void> refresh() {
    final provider = _timeScheduleDataProvider(_query!);
    return reloadFrom(ref, [
      authSessionProvider,
      followsProvider,
      provider,
    ], awaiting: () => ref.read(provider.future));
  }

  /// 日か絞り込みを変える。読み込むあいだは、前のデータを出しておく。
  void _select(TimeScheduleState next) =>
      state = next.copyWith(result: _watchData(next));

  /// [next] の日と絞り込みのデータを聞き、今の値を返す。
  AsyncValue<TimeScheduleData> _watchData(TimeScheduleState next) {
    final query = _TimeScheduleQuery(day: next.day, filter: next.filter);
    final provider = _timeScheduleDataProvider(query);
    if (query != _query) {
      _subscription?.close();
      _query = query;
      _subscription = ref.listen(
        provider,
        (_, result) => state = state.copyWith(result: result),
      );
    }
    return ref.read(provider);
  }
}

final timeScheduleViewModelProvider =
    NotifierProvider<TimeScheduleViewModel, TimeScheduleState>(
      TimeScheduleViewModel.new,
    );

/// 読むデータを決める、選んだ日と絞り込み。Provider のキーに使うので、値で等しさを決める。
class _TimeScheduleQuery {
  const _TimeScheduleQuery({required this.day, required this.filter});

  final DateTime day;
  final ScheduleFilter filter;

  /// 週の始まり（日曜）。
  DateTime get weekStart => day.subtract(Duration(days: day.weekday % 7));

  @override
  bool operator ==(Object other) =>
      other is _TimeScheduleQuery && other.day == day && other.filter == filter;

  @override
  int get hashCode => Object.hash(day, filter);
}

/// 選んだ週の予定と投稿を読み、選んだ日のぶんに絞る。1分ごとに読み直す。
final _timeScheduleDataProvider = FutureProvider.autoDispose
    .family<TimeScheduleData, _TimeScheduleQuery>((ref, query) async {
      final oshis = await ref.watch(oshisProvider.future);
      final weekStart = query.weekStart;
      final from = weekStart.subtract(const Duration(days: 1));
      final until = weekStart.add(const Duration(days: 8));
      final ids = [for (final o in oshis) o.id];
      final schedules = ids.isEmpty
          ? const <ScheduleItem>[]
          : await ref.watch(
              schedulesProvider(
                ScheduleRange(creatorIds: ids, from: from, until: until),
              ).future,
            );
      // 追星から投稿を消したら、読み直す（機能仕様書 4.4.4）。
      ref.watch(removedPostsProvider);
      refreshPeriodically(ref);
      final posts = ids.isEmpty
          ? const <Post>[]
          : await ref
                .read(postRepositoryProvider)
                .fetchTimeline(
                  ids,
                  limit: creatorPostsLimit,
                  since: weekStart,
                  before: weekStart.add(const Duration(days: 7)),
                );
      final filter = query.filter;
      final shownIds = filter.shownCreatorIds(ids);
      final shown = oshis.where((o) => shownIds.contains(o.id)).toList();
      bool scheduleShown(ScheduleItem s) => filter.showsSchedule(s, shownIds);
      bool postShown(Post p) => filter.showsPost(p, shownIds);
      final daySchedules = [
        for (final s in schedules)
          // 終了のない予定は、イベントはその日の終わりまで、配信は1時間で重なりを見る（機能仕様書 4.5.3）。
          if (scheduleShown(s) && s.overlapsDay(query.day)) s,
      ];
      final dayPosts = [
        for (final p in posts)
          if (postShown(p) && isSameDay(p.postedAt, query.day)) p,
      ];
      return TimeScheduleData(
        day: query.day,
        allOshis: oshis,
        oshis: shown,
        schedules: daySchedules,
        posts: dayPosts,
      );
    });

/// 下部ナビのスケジュールを、スケジュールを開いているときにもう一度押した合図（画面定義書（スケジュール）2.1.1）。
/// 値が変わるたびに、タイムスケジュールが今日に戻り、今の時刻を表の真ん中へ移す。
class ScheduleScrollToNow extends Notifier<int> {
  @override
  int build() => 0;

  void request() => state++;
}

final scheduleScrollToNowProvider = NotifierProvider<ScheduleScrollToNow, int>(
  ScheduleScrollToNow.new,
);
