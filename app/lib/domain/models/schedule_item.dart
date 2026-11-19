import '../../utils/formatters.dart';
import '../../utils/server_time.dart';
import 'sns_service.dart';

/// 予定（イベントの公演・配信の予約）。`schedules` テーブルの1行。
/// 終わった配信（実績。`live_records` の1行）も、同じ形で出す（機能仕様書 4.5.4）。
class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.startsAt,
    this.endsAt,
    this.allDay = false,
    this.service,
    this.venue,
    this.ticketUrl,
    this.ticketIsPromotion = false,
    this.fetched = false,
    this.externalId,
    this.record = false,
    this.eventId,
    this.performanceUrl,
  });

  factory ScheduleItem.fromRow(Map<String, dynamic> row) => ScheduleItem(
    id: row['id'] as String,
    creatorId: row['creator_id'] as String,
    title: row['title'] as String,
    startsAt: parseTime(row['starts_at'] as String)!,
    endsAt: parseTime(row['ends_at'] as String?),
    allDay: (row['all_day'] as bool?) ?? false,
    service: SnsService.fromName(row['service'] as String?),
    venue: row['venue'] as String?,
    ticketUrl: row['ticket_url'] as String?,
    ticketIsPromotion: (row['ticket_is_promotion'] as bool?) ?? false,
    fetched: row['external_id'] != null,
    externalId: row['external_id'] as String?,
    eventId: row['event_id'] as String?,
    performanceUrl: row['performance_url'] as String?,
  );

  /// 終わった配信（`live_records` の1行）。実際の開始から終了までの予定として出す。
  factory ScheduleItem.fromLiveRecord(Map<String, dynamic> row) {
    final title = (row['title'] as String?)?.trim() ?? '';
    return ScheduleItem(
      id: 'record:${row['service']}:${row['live_id']}',
      creatorId: row['creator_id'] as String,
      // タイトルのない配信は、View で「配信」（`commonLive`）と出す。
      title: title,
      startsAt: parseTime(row['started_at'] as String)!,
      endsAt: parseTime(row['ended_at'] as String?),
      service: SnsService.fromName(row['service'] as String?),
      record: true,
    );
  }

  final String id;
  final String creatorId;
  final String title;
  final DateTime startsAt;

  /// 終了の時刻。空なら、発信者が設定したデフォルトの長さで描く。
  final DateTime? endsAt;

  /// 終日（時刻のない予定）。
  final bool allDay;

  /// プラットフォーム。会場で行うイベントなどは null（汎用のアイコンで出す）。
  final SnsService? service;

  /// 会場。
  final String? venue;

  /// リンク（チケットの販売など）。画面では「リンク」と呼ぶ。
  final String? ticketUrl;

  /// リンクが広告なら true。「PR」と表示する。
  final bool ticketIsPromotion;

  /// 配信サービスから取った予約か（機能仕様書 4.5.1。`external_id` を持つ）。
  final bool fetched;

  /// 取った予約の、配信サービスでの ID（`external_id`）。YouTube なら動画の ID。
  final String? externalId;

  /// 終わった配信（実績。`live_records` の1行）か。
  final bool record;

  /// イベント（`events`）の公演なら、そのイベントの ID（データ設計書 3.1.17）。
  final String? eventId;

  /// イベントの公演なら、公演のページ（1公演の日時と会場が分かるページ）の URL。
  final String? performanceUrl;

  /// イベントの公演で、開演の時刻が決まっていないか。終日として持ち、画面では「時刻未定」と出す。
  bool get timeTbd => eventId != null && allDay;

  /// 発信者が登録したイベントの公演か（機能仕様書 4.5.2）。オーナーが編集・削除できるのは、これだけ。
  /// 発信者が手で作れる予定は、イベントの公演だけ（データ設計書 3.1.16 の制約）。
  bool get isEventPerformance => eventId != null;

  /// アプリに出すか。取得した予約と実績は、この版で出さない SNS（[SnsService.offered]。v1.0.0 のツイキャス）なら出さない
  /// （機能仕様書 4.5.1・4.5.4）。発信者が手で登録した予定は、プラットフォームによらず出す。
  bool get offered => !(fetched || record) || (service?.offered ?? true);

  /// 配信の予定か（配信サービスのプラットフォームを持つ）。
  bool get isLive => service?.hasLive ?? false;

  /// イベントか（会場で行うイベントや、チケットのあるイベント）。プラットフォームを持たない予定をイベントとする。
  bool get isEvent => service == null;

  /// 終了時刻のない配信の予定を描く長さ（分。機能仕様書 4.5.3）。
  static const liveFallbackMinutes = 60;

  /// 描く終了時刻（機能仕様書 4.5.3、2026-11-19 本人）。終了が空なら、イベント（プラットフォームのない予定。公演）は
  /// 始まった日の終わり（24:00）まで、配信などは [liveFallbackMinutes] 分で描く。
  DateTime get displayEnd {
    if (endsAt case final end?) return end;
    if (isEvent) {
      final day = dateOnly(startsAt.toLocal());
      return DateTime(day.year, day.month, day.day + 1);
    }
    return startsAt.add(const Duration(minutes: liveFallbackMinutes));
  }

  /// 終わった予定か。終日の予定は、その日が過ぎたら終わり。終了時刻のないイベントは、その日が終わったら終わり。
  bool isPastAt(DateTime now) =>
      allDay ? _allDayPastAt(now) : !displayEnd.isAfter(now);

  /// 終わったイベントか（画面定義書（スケジュール）2.3.1）。イベント一覧とイベントの詳細で同じ判定を使う。
  /// 終了時刻を過ぎたら終わり（終了時刻がなければ開始を過ぎたら）。終日なら、その日が過ぎたら。
  bool hasEndedAt(DateTime now) =>
      allDay ? _allDayPastAt(now) : !(endsAt ?? startsAt).isAfter(now);

  /// 終日の予定の日が、[now] の日より前か。
  bool _allDayPastAt(DateTime now) =>
      dateOnly(startsAt.toLocal()).isBefore(dateOnly(now.toLocal()));

  /// 開始から終了までのうち、[day] の日に重なるか。
  bool overlapsDay(DateTime day) {
    final dayStart = dateOnly(day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    if (allDay) {
      return !startsAt.isBefore(dayStart) && startsAt.isBefore(dayEnd);
    }
    return startsAt.isBefore(dayEnd) && displayEnd.isAfter(dayStart);
  }

  /// 保存する行（登録・編集で使う）。
  Map<String, dynamic> toRow() => {
    'creator_id': creatorId,
    'title': title,
    'starts_at': startsAt.toServerTime(),
    'ends_at': endsAt?.toServerTime(),
    'all_day': allDay,
    'service': service?.name,
    'venue': venue,
    'ticket_url': ticketUrl,
    'ticket_is_promotion': ticketIsPromotion,
  };
}
