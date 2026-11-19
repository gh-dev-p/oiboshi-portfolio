import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/schedule_item.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import 'creator_admin_providers.dart';

/// イベントの管理の画面に出すもの。
class EventManageState {
  const EventManageState({required this.upcoming, required this.past});

  /// これからの公演（古い順）。
  final List<ScheduleItem> upcoming;

  /// 過去の公演（新しい順）。
  final List<ScheduleItem> past;

  bool get isEmpty => upcoming.isEmpty && past.isEmpty;
}

/// イベントの管理（画面定義書 2.3.7）。自分のイベントの公演を、これからと過去に分ける。
/// 取得した配信の予約は出さない。登録・編集・削除のあとは、イベントの登録が読み直させる（[refreshCreatorSchedules]）。
class EventManageViewModel extends AsyncNotifier<EventManageState> {
  EventManageViewModel(this.creatorId);

  final String creatorId;

  @override
  Future<EventManageState> build() => withSession(ref, (_) async {
    final items = await ref
        .watch(scheduleRepositoryProvider)
        .fetchCreatorPerformances(creatorId);
    return split(items, now: ref.read(clockProvider)());
  });

  /// [items] を、これからの公演（古い順）と、過去の公演（新しい順）に分ける。
  /// 過去の公演は、終わった公演（終了のない公演は、その日の終わりで終わるとみなす（2026-11-19 本人）。
  /// 終日は前の日までのもの）。
  static EventManageState split(
    List<ScheduleItem> items, {
    required DateTime now,
  }) {
    bool isPast(ScheduleItem s) => s.isPastAt(now);
    final sorted = [...items]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return EventManageState(
      upcoming: [
        for (final s in sorted)
          if (!isPast(s)) s,
      ],
      past: [
        for (final s in sorted.reversed)
          if (isPast(s)) s,
      ],
    );
  }

  /// 読み込めなかったときに、読み直す。
  void retry() {
    retryCreatorAdmin(ref, creatorId);
    ref.invalidateSelf();
  }
}

final eventManageViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<EventManageViewModel, EventManageState, String>(
      EventManageViewModel.new,
    );
