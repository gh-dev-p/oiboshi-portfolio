import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/service_providers.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/schedule_filter.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../utils/formatters.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../core/view_models/removed_posts_provider.dart';
import '../../core/view_models/value_key.dart';
import 'schedule_providers.dart';

/// 月のカレンダーを開く条件（出す発信者と、最初に選ぶ日）。Provider のキーに使うので、値で等しさを決める。
class MonthCalendarKey extends ProviderKey {
  const MonthCalendarKey({required this.creatorIds, required this.initialDay});

  final List<String> creatorIds;
  final DateTime initialDay;

  @override
  List<Object?> get props => [creatorIds, initialDay];
}

/// 月のカレンダーの、1か月ぶんの予定と実績。
class MonthData {
  const MonthData({required this.schedules, required this.posts});

  final List<ScheduleItem> schedules;

  /// 実績（残してある投稿）。
  final List<Post> posts;

  /// その日の予定（開始がその日）。
  List<ScheduleItem> schedulesOn(DateTime day) =>
      schedules.where((s) => isSameDay(s.startsAt, day)).toList();

  /// [filter] で絞ったデータ。[creatorIds] は、カレンダーに出している推し全員。
  MonthData filtered(ScheduleFilter filter, Iterable<String> creatorIds) {
    final shownIds = filter.shownCreatorIds(creatorIds);
    return MonthData(
      schedules: [
        for (final s in schedules)
          if (filter.showsSchedule(s, shownIds)) s,
      ],
      posts: [
        for (final p in posts)
          if (filter.showsPost(p, shownIds)) p,
      ],
    );
  }

  List<Post> postsOn(DateTime day) =>
      posts.where((p) => isSameDay(p.postedAt, day)).toList();

  /// その日に配信（予定）があるか、イベントの公演があるか、投稿があるか（月のグリッドでは、配信・投稿・イベントの順に点を並べる）。
  /// 投稿は、選んだ日のパネルに出すものと同じ（その月のデータとして読んだ投稿。点のために読み込みは足さない）。
  ({bool live, bool event, bool post}) dotsOn(DateTime day) {
    final items = schedulesOn(day);
    return (
      live: items.any((s) => s.isLive),
      event: items.any((s) => !s.isLive),
      post: posts.any((p) => isSameDay(p.postedAt, day)),
    );
  }
}

/// 出している月・選んだ日と、その月のデータ、みんなのカレンダーの絞り込み。
class MonthCalendarState {
  const MonthCalendarState({
    required this.month,
    required this.selected,
    this.data = const AsyncLoading(),
    this.filter = const ScheduleFilter(),
  });

  /// その月の1日。
  final DateTime month;
  final DateTime selected;

  /// 出している月のデータ。月を移すと読み直す（読み直しに失敗したときは、前の値を保つ）。
  final AsyncValue<MonthData> data;

  /// みんなのカレンダーの絞り込み（アプリを起動しているあいだ保つ）。絞り込める画面だけが使う。
  final ScheduleFilter filter;

  MonthCalendarState copyWith({
    DateTime? month,
    DateTime? selected,
    AsyncValue<MonthData>? data,
    ScheduleFilter? filter,
  }) => MonthCalendarState(
    month: month ?? this.month,
    selected: selected ?? this.selected,
    data: data ?? this.data,
    filter: filter ?? this.filter,
  );
}

/// 月のカレンダー（画面定義書 2.2.1）の操作（月・選んだ日・読み直し）。
/// 出している月に合わせて、1か月ぶんのデータを読み、state に載せる。
class MonthCalendarViewModel extends Notifier<MonthCalendarState> {
  MonthCalendarViewModel(this.key);

  final MonthCalendarKey key;
  ProviderSubscription<AsyncValue<MonthData>>? _subscription;
  _MonthQuery? _query;

  @override
  MonthCalendarState build() {
    ref.onDispose(() => _subscription?.close());
    ref.listen(
      allScheduleFilterProvider,
      (_, filter) => state = state.copyWith(filter: filter),
    );
    final month = DateTime(key.initialDay.year, key.initialDay.month, 1);
    return MonthCalendarState(
      month: month,
      selected: dateOnly(key.initialDay),
      data: _watchData(month),
      filter: ref.read(allScheduleFilterProvider),
    );
  }

  void selectDay(DateTime day) =>
      state = state.copyWith(selected: dateOnly(day));

  /// 月を [delta] か月ぶん移す。今日を含む月なら今日を、それ以外は1日を選ぶ。
  void moveMonth(int delta) {
    final month = DateTime(state.month.year, state.month.month + delta, 1);
    final today = dateOnly(ref.read(clockProvider)());
    state = MonthCalendarState(
      month: month,
      selected:
          isSameDay(today, month) ||
              (today.year == month.year && today.month == month.month)
          ? today
          : month,
      data: _watchData(month),
      filter: state.filter,
    );
  }

  /// みんなのカレンダーの絞り込みを変える。
  void setFilter(ScheduleFilter filter) =>
      ref.read(allScheduleFilterProvider.notifier).set(filter);

  /// 読み直す（「もう一度試す」）。
  void retry() =>
      reloadFrom(ref, [authSessionProvider, _monthDataProvider(_query!)]);

  /// [month] のデータを聞き、今の値を返す。
  AsyncValue<MonthData> _watchData(DateTime month) {
    final query = _MonthQuery(
      creatorIds: key.creatorIds,
      year: month.year,
      month: month.month,
    );
    final provider = _monthDataProvider(query);
    if (query != _query) {
      _subscription?.close();
      _query = query;
      _subscription = ref.listen(
        provider,
        (_, data) => state = state.copyWith(data: data),
      );
    }
    return ref.read(provider);
  }
}

final monthCalendarViewModelProvider = NotifierProvider.autoDispose
    .family<MonthCalendarViewModel, MonthCalendarState, MonthCalendarKey>(
      MonthCalendarViewModel.new,
    );

/// 読むデータを決める、発信者と月。Provider のキーに使うので、値で等しさを決める。
class _MonthQuery extends ProviderKey {
  const _MonthQuery({
    required this.creatorIds,
    required this.year,
    required this.month,
  });

  final List<String> creatorIds;
  final int year;
  final int month;

  @override
  List<Object?> get props => [creatorIds, year, month];
}

/// 指定の発信者・月のデータ。1分ごとに読み直す。
final _monthDataProvider = FutureProvider.autoDispose
    .family<MonthData, _MonthQuery>(
      (ref, query) => withSession(ref, (_) async {
        final from = DateTime(query.year, query.month, 1);
        final until = DateTime(query.year, query.month + 1, 1);
        final schedules = await ref.watch(
          schedulesProvider(
            ScheduleRange(
              creatorIds: query.creatorIds,
              from: from,
              until: until,
            ),
          ).future,
        );
        // 追星から投稿を消したら、読み直す（機能仕様書 4.4.4）。
        ref.watch(removedPostsProvider);
        refreshPeriodically(ref);
        final posts = query.creatorIds.isEmpty
            ? const <Post>[]
            : await ref
                  .watch(postRepositoryProvider)
                  .fetchTimeline(
                    query.creatorIds,
                    limit: creatorPostsLimit,
                    since: from,
                    before: until,
                  );
        return MonthData(schedules: schedules, posts: posts);
      }),
    );
