import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/schedule_item.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/refresh.dart';
import 'schedule_providers.dart';

/// イベント一覧（画面定義書（スケジュール）2.3.1）。[key] の発信者の、これからのイベント。
/// 読み込み中と失敗も、そのまま state に入れる。
class EventListViewModel extends Notifier<AsyncValue<List<ScheduleItem>>> {
  EventListViewModel(this.key);

  final EventsKey key;

  @override
  AsyncValue<List<ScheduleItem>> build() => ref.watch(eventsProvider(key));

  /// 読み直す（「もう一度試す」、引いて更新）。
  Future<void> refresh() => reloadFrom(ref, [
    authSessionProvider,
    eventsProvider(key),
  ], awaiting: () => ref.read(eventsProvider(key).future));
}

final eventListViewModelProvider = NotifierProvider.autoDispose
    .family<EventListViewModel, AsyncValue<List<ScheduleItem>>, EventsKey>(
      EventListViewModel.new,
    );
