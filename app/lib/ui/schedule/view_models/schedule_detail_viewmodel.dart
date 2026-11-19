import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';

import '../../../domain/models/event.dart';
import '../../../domain/models/report.dart';
import '../../../domain/models/schedule_item.dart';
import '../../settings/view_models/settings_providers.dart';
import 'schedule_providers.dart';

/// 予定の詳細に出すもの。自分がオーナーの発信者（ボタンの出し分けに使う）と、イベントのリンク。
class ScheduleDetailState {
  const ScheduleDetailState({
    required this.ownedCreatorId,
    required this.ownedKnown,
    this.eventLinks,
  });

  /// 自分がオーナーの発信者の ID。発信者でなければ null。
  final String? ownedCreatorId;

  /// 自分がオーナーかが分かったか（読めなかったときも、オーナーでないものとして true）。
  final bool ownedKnown;

  /// イベントの表から読んだリンク（何本でも）。イベントを読まないとき・まだ読めていないときは null。
  final List<EventLink>? eventLinks;

  /// 「この予定を通報する」を出すか。イベントの公演で、自分がオーナーでないときだけ（機能仕様書 4.2.7）。
  bool canReport(ScheduleItem item) =>
      item.isEventPerformance && ownedKnown && ownedCreatorId != item.creatorId;
}

/// 予定の詳細（シート）と、詳細のパネルの予定のカード、イベントの詳細（画面定義書（スケジュール）2.1.3・2.1.5・2.3.2）。
/// [eventId] を渡したとき（イベントの詳細）は、そのイベントのリンクも読む。
class ScheduleDetailViewModel extends Notifier<ScheduleDetailState> {
  ScheduleDetailViewModel(this.eventId);

  final String? eventId;

  @override
  ScheduleDetailState build() {
    final owned = ref.watch(ownedCreatorProvider);
    final id = eventId;
    return ScheduleDetailState(
      ownedCreatorId: owned.value?.id,
      ownedKnown: owned.hasValue || owned.hasError,
      eventLinks: id == null ? null : ref.watch(eventProvider(id)).value?.links,
    );
  }

  /// [item] の通報の対象。
  ReportTarget reportTarget(ScheduleItem item, String title) =>
      ScheduleReportTarget(scheduleId: item.id, title: title);
}

/// 予定の詳細を開いたことを、発信者に見せる数に記録する（届ける・広める仕様書 4.2.1）。予定の詳細のカードが出ているあいだ、
/// 1回だけ送る（同じ日に同じ人が何回開いても、サーバーが1回にまとめる）。終わった配信（実績）は予定ではないので、呼ぶ側が送らない。
final scheduleViewRecorderProvider = Provider.autoDispose
    .family<void, ({String creatorId, String scheduleId})>((ref, key) {
      unawaited(
        ref
            .read(reachRepositoryProvider)
            .recordViewed(key.creatorId, key.scheduleId),
      );
    });

final scheduleDetailViewModelProvider = NotifierProvider.autoDispose
    .family<ScheduleDetailViewModel, ScheduleDetailState, String?>(
      ScheduleDetailViewModel.new,
    );
