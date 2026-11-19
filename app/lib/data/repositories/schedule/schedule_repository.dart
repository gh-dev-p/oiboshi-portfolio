import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/event.dart';
import '../../../domain/models/event_draft.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../utils/server_time.dart';
import '../../services/schedule/schedule_service.dart';
import '../common/error_mapping.dart';

/// 予定を読み書きする。
class ScheduleRepository {
  ScheduleRepository(this._service);

  final ScheduleService _service;

  /// [creatorIds] の予定と、終わった配信（実績）のうち、開始が [from] 以降で [until] より前のものを古い順に。
  /// [includeOngoing] なら、[from] より前に始まった予定も、終了が [from] 以降なら含める（開催中のイベント）。
  /// 実績と二重になる、取得した予約は除く（[withoutRecordedReservations]）。
  Future<List<ScheduleItem>> fetchRange(
    List<String> creatorIds, {
    required DateTime from,
    required DateTime until,
    bool includeOngoing = false,
  }) => mapErrors(() async {
    final rows = await _service.fetchRange(
      creatorIds,
      from: from,
      until: until,
      includeOngoing: includeOngoing,
    );
    final records = await _service.fetchLiveRecords(
      creatorIds,
      from: from,
      until: until,
    );
    // この版で出さない SNS（v1.0.0 のツイキャス）の、取得した予約と実績は読まない（[ScheduleItem.offered]）。
    final recorded = records
        .map(ScheduleItem.fromLiveRecord)
        .where((r) => r.offered)
        .toList();
    final schedules = rows.map(ScheduleItem.fromRow).where((s) => s.offered);
    return [...withoutRecordedReservations(schedules, recorded), ...recorded]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  });

  /// 取得した予約が残る長さ（機能仕様書 4.5.1。まだ始まっていない予約は、開始予定から12時間まで残す）。
  static const reservationKeep = Duration(hours: 12);

  /// 開始予定より早く始めた配信も、その予約の配信とみなす幅。
  static const earlyStart = Duration(minutes: 30);

  /// [schedules] から、同じ発信者・サービスの実績（[records]）が、開始予定の [earlyStart] 前から
  /// [reservationKeep] 後までに始まっている、取得した予約を除く（機能仕様書 4.5.4）。
  /// 始まった配信の予約は次の取得（30分ごと）で消えるが、それまで実績と二重に出さないため。
  static Iterable<ScheduleItem> withoutRecordedReservations(
    Iterable<ScheduleItem> schedules,
    List<ScheduleItem> records,
  ) => schedules.where(
    (s) =>
        !s.fetched ||
        !records.any(
          (r) =>
              r.creatorId == s.creatorId &&
              r.service == s.service &&
              !r.startsAt.isBefore(s.startsAt.subtract(earlyStart)) &&
              r.startsAt.isBefore(s.startsAt.add(reservationKeep)),
        ),
  );

  /// [creatorId] のイベントの公演（取得した予約を除く予定）を、古い順に（機能仕様書 4.5.2）。
  Future<List<ScheduleItem>> fetchCreatorPerformances(String creatorId) =>
      mapErrors(() async {
        final rows = await _service.fetchCreatorPerformances(creatorId);
        return rows.map(ScheduleItem.fromRow).toList();
      });

  /// 予定を1件読む（予定の事前通知を押したとき。届ける・広める仕様書 4.1.1）。消えた・この版で出さない SNS なら null。
  Future<ScheduleItem?> fetchSchedule(String id) => mapErrors(() async {
    final row = await _service.fetchSchedule(id);
    final item = row == null ? null : ScheduleItem.fromRow(row);
    return item != null && item.offered ? item : null;
  });

  /// イベントを、リンクと公演ごと読む。なければ null。
  Future<Event?> fetchEvent(String id) => mapErrors(() async {
    final row = await _service.fetchEvent(id);
    if (row == null) return null;
    final links = await _service.fetchEventLinks(id);
    final performances = await _service.fetchEventPerformances(id);
    return Event(
      id: id,
      creatorId: row['creator_id'] as String,
      title: row['title'] as String,
      links: links.map(EventLink.fromRow).toList(),
      performances: performances.map(ScheduleItem.fromRow).toList(),
    );
  });

  /// イベントを、リンクと公演ごとまとめて保存する（[id] があれば編集）。保存したイベントの ID を返す。
  /// 同じチケットのページを指すリンクが、ほかのイベントにあれば [EventSaveException]（[EventSaveError.duplicateLink]）。
  Future<String> saveEvent({
    String? id,
    required String creatorId,
    required String title,
    required List<EventLink> links,
    required List<ScheduleItem> performances,
  }) async {
    try {
      return await _service.saveEvent({
        'id': ?id,
        'creator_id': creatorId,
        'title': title,
        'links': [
          for (final l in links) {'url': l.url, 'is_promotion': l.isPromotion},
        ],
        'performances': [
          for (final p in performances)
            {
              'starts_at': p.startsAt.toServerTime(),
              'ends_at': p.endsAt?.toServerTime(),
              'all_day': p.allDay,
              'venue': p.venue,
              'url': p.performanceUrl,
            },
        ],
      });
    } on PostgrestException catch (e) {
      if (e.code == PgCodes.uniqueViolation) {
        throw const EventSaveException(EventSaveError.duplicateLink);
      }
      throw const EventSaveException(EventSaveError.failed);
    } catch (_) {
      throw const EventSaveException(EventSaveError.failed);
    }
  }

  /// イベントを消す（リンクと公演も消える）。
  Future<void> deleteEvent(String id) =>
      mapErrors(() => _service.deleteEvent(id));

  /// 渡した URL のうち、その発信者のイベントに登録済みのもの（形をそろえて比べる）。
  Future<Set<String>> registeredEventUrls(
    String creatorId,
    List<String> urls,
  ) => mapErrors(
    () async => (await _service.registeredEventUrls(creatorId, urls)).toSet(),
  );

  /// 発信者が開いたチケットのページ（[url]）から取り出した部分（[html]）を読み取って、イベントの下書きを返す。
  /// 読み取れなかったら null。
  Future<EventDraft?> readEventUrl(String url, {required String html}) =>
      mapErrors(() async {
        try {
          return EventDraft.fromJson(
            await _service.readEventUrl(url, html: html),
          );
        } on FunctionException catch (e) {
          // 読めないページ・受け付けない URL は、下書きなし（手で入れてもらう）。
          if (e.status == 400 || e.status == 422) return null;
          rethrow;
        }
      });
}
