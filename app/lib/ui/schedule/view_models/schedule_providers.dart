import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/service_providers.dart';
import '../../../domain/models/event.dart';
import '../../../domain/models/schedule_filter.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../utils/formatters.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../core/view_models/value_key.dart';
import '../../oshi/view_models/oshi_providers.dart';

/// 予定を読む範囲。Provider のキーに使うので、値で等しさを決める。
class ScheduleRange extends ProviderKey {
  const ScheduleRange({
    required this.creatorIds,
    required this.from,
    required this.until,
    this.includeOngoing = false,
  });

  /// [creatorIds] の、昨日から [nextScheduleRange]（1年）先まで。
  /// 開催中のイベント（昨日より前に始まり、まだ終わっていないもの）も読む。
  /// 範囲は日で切る。時刻を入れると、読み直すたびにキーが変わり、同じ範囲を読み直してしまう。
  factory ScheduleRange.ahead(List<String> creatorIds, DateTime now) {
    final today = dateOnly(now);
    return ScheduleRange(
      creatorIds: creatorIds,
      from: today.subtract(const Duration(days: 1)),
      until: today.add(nextScheduleRange),
      includeOngoing: true,
    );
  }

  final List<String> creatorIds;
  final DateTime from;
  final DateTime until;

  /// [from] より前に始まった予定も、終了が [from] 以降なら読むか。
  final bool includeOngoing;

  @override
  List<Object?> get props => [creatorIds, from, until, includeOngoing];
}

/// 指定の発信者・期間の予定。1分ごとに読み直す。
final schedulesProvider = FutureProvider.autoDispose
    .family<List<ScheduleItem>, ScheduleRange>(
      (ref, range) => withSession(ref, (_) {
        refreshPeriodically(ref);
        return ref
            .watch(scheduleRepositoryProvider)
            .fetchRange(
              range.creatorIds,
              from: range.from,
              until: range.until,
              includeOngoing: range.includeOngoing,
            );
      }),
    );

/// 推し全員の、昨日から1年先までの予定（終日も含む）。
final _oshiSchedulesAheadProvider =
    FutureProvider.autoDispose<List<ScheduleItem>>((ref) async {
      final oshis = await ref.watch(oshisProvider.future);
      if (oshis.isEmpty) return const [];
      final range = ScheduleRange.ahead([
        for (final o in oshis) o.id,
      ], ref.read(clockProvider)());
      return ref.watch(schedulesProvider(range).future);
    });

/// 推し全員の、これからの予定（1年以内）。ホームの「次の予定」と推しリストで使う。
final upcomingSchedulesProvider =
    FutureProvider.autoDispose<List<ScheduleItem>>((ref) async {
      final now = ref.read(clockProvider)();
      final items = await ref.watch(_oshiSchedulesAheadProvider.future);
      return items.where((s) => !s.allDay && s.startsAt.isAfter(now)).toList();
    });

/// これからのイベントか。開催中のもの（終了時刻の前。終了時刻がなければ開始の前。終日なら、その日のあいだ）も含む。
/// 終わったかは、イベントの詳細と同じ [ScheduleItem.hasEndedAt] で決める。
bool isUpcomingEvent(ScheduleItem s, DateTime now) =>
    s.isEvent && !s.hasEndedAt(now);

/// 推し全員の、これからのイベント（1年以内）。開催中のものも含む。ホームの「イベント」で使う。
final upcomingEventsProvider = FutureProvider.autoDispose<List<ScheduleItem>>((
  ref,
) async {
  final now = ref.read(clockProvider)();
  final items = await ref.watch(_oshiSchedulesAheadProvider.future);
  return items.where((s) => isUpcomingEvent(s, now)).toList();
});

/// 発信者を指定した、これからのイベント（1年以内）。Provider のキーに使うので、値で等しさを決める。
class EventsKey extends ProviderKey {
  const EventsKey(this.creatorIds);

  final List<String> creatorIds;

  @override
  List<Object?> get props => [creatorIds];
}

/// 指定の発信者の、これからのイベント（1年以内）。開催中のものも含む。発信者ページの「イベント」とイベント一覧で使う。
final eventsProvider = FutureProvider.autoDispose
    .family<List<ScheduleItem>, EventsKey>((ref, key) async {
      if (key.creatorIds.isEmpty) return const [];
      final now = ref.read(clockProvider)();
      final range = ScheduleRange.ahead(key.creatorIds, now);
      final items = await ref.watch(schedulesProvider(range).future);
      return items.where((s) => isUpcomingEvent(s, now)).toList();
    });

/// イベント（リンクと公演を含む）。イベントの詳細と、イベントの編集で使う。
final eventProvider = FutureProvider.autoDispose.family<Event?, String>(
  (ref, id) => withSession(
    ref,
    (_) => ref.watch(scheduleRepositoryProvider).fetchEvent(id),
  ),
);

/// 1人の発信者の、次の予定。終日の予定とイベントは選ばない（イベントは、発信者ページの「イベント」に出す）。
final nextScheduleProvider = FutureProvider.autoDispose
    .family<ScheduleItem?, String>((ref, creatorId) async {
      final now = ref.read(clockProvider)();
      final range = ScheduleRange.ahead([creatorId], now);
      final items = await ref.watch(schedulesProvider(range).future);
      return items
          .where((s) => !s.allDay && !s.isEvent && !s.startsAt.isBefore(now))
          .firstOrNull;
    });

/// みんなのカレンダーの絞り込み（画面定義書 2.2.1）。タイムスケジュールとは別に持ち、アプリを起動しているあいだ保つ。
class AllScheduleFilter extends Notifier<ScheduleFilter> {
  @override
  ScheduleFilter build() => const ScheduleFilter();

  void set(ScheduleFilter filter) => state = filter;
}

final allScheduleFilterProvider =
    NotifierProvider<AllScheduleFilter, ScheduleFilter>(AllScheduleFilter.new);
