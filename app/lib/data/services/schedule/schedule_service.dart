import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/server_time.dart';
import '../common/edge_functions.dart';
import '../common/paging.dart';
import '../common/supabase_names.dart';

/// 予定のテーブルの読み書き。
class ScheduleService {
  ScheduleService(this._client);

  final SupabaseClient _client;

  SupabaseQueryBuilder get _schedules => _client.from(Tables.schedules);

  /// [creatorIds] の予定のうち、開始が [from] 以降で [until] より前のものを古い順に。
  /// 1回に読める行数（[serverMaxRows]）を超えても、続きを読んで全部返す。
  /// [includeOngoing] なら、開始が [from] より前でも、終了が [from] 以降のもの（開催中）を含める。
  Future<List<Map<String, dynamic>>> fetchRange(
    List<String> creatorIds, {
    required DateTime from,
    required DateTime until,
    bool includeOngoing = false,
  }) async {
    if (creatorIds.isEmpty) return const [];
    final fromTime = from.toServerTime();
    return fetchAllPages((first, last) {
      final query = _schedules
          .select()
          .inFilter('creator_id', creatorIds)
          .lt('starts_at', until.toServerTime());
      return (includeOngoing
              ? query.or('starts_at.gte."$fromTime",ends_at.gte."$fromTime"')
              : query.gte('starts_at', fromTime))
          .order('starts_at', ascending: true)
          .order('id', ascending: true)
          .range(first, last);
    });
  }

  /// [creatorId] のイベントの公演（取得した予約を除く予定）を、古い順に。
  Future<List<Map<String, dynamic>>> fetchCreatorPerformances(String creatorId) =>
      _schedules
          .select()
          .eq('creator_id', creatorId)
          .isFilter('external_id', null)
          .order('starts_at', ascending: true);

  /// [creatorIds] の終わった配信（実績）のうち、開始が [from] 以降で [until] より前のものを古い順に。
  /// 1回に読める行数（[serverMaxRows]）を超えても、続きを読んで全部返す。
  Future<List<Map<String, dynamic>>> fetchLiveRecords(
    List<String> creatorIds, {
    required DateTime from,
    required DateTime until,
  }) async {
    if (creatorIds.isEmpty) return const [];
    return fetchAllPages(
      (first, last) => _client
          .from(Tables.liveRecords)
          .select()
          .inFilter('creator_id', creatorIds)
          .not('ended_at', 'is', null)
          .gte('started_at', from.toServerTime())
          .lt('started_at', until.toServerTime())
          // 並びを毎回同じにする（主キーの順まで決める）。
          .order('started_at', ascending: true)
          .order('creator_id', ascending: true)
          .order('service', ascending: true)
          .order('live_id', ascending: true)
          .range(first, last),
    );
  }

  /// イベントの本体（`events` の1行）。なければ null。
  Future<Map<String, dynamic>?> fetchEvent(String id) =>
      _client.from(Tables.events).select().eq('id', id).maybeSingle();

  /// 予定を1件読む（予定の事前通知を押したとき）。なければ null。
  Future<Map<String, dynamic>?> fetchSchedule(String id) =>
      _schedules.select().eq('id', id).maybeSingle();

  /// イベントのリンク（並び順）。
  Future<List<Map<String, dynamic>>> fetchEventLinks(String eventId) => _client
      .from(Tables.eventLinks)
      .select()
      .eq('event_id', eventId)
      .order('position', ascending: true);

  /// イベントの公演（日時の順）。
  Future<List<Map<String, dynamic>>> fetchEventPerformances(String eventId) =>
      _schedules
          .select()
          .eq('event_id', eventId)
          .order('starts_at', ascending: true);

  /// イベントを、リンクと公演ごとまとめて保存する（関数 `save_event`）。イベントの ID を返す。
  Future<String> saveEvent(Map<String, dynamic> event) =>
      _client.rpc<String>(Functions.saveEvent, params: {'p_event': event});

  /// イベントを消す（リンクと公演も消える）。
  Future<void> deleteEvent(String id) =>
      _client.from(Tables.events).delete().eq('id', id);

  /// 渡した URL のうち、その発信者のイベントに登録済みのもの。
  Future<List<String>> registeredEventUrls(
    String creatorId,
    List<String> urls,
  ) async {
    final rows = await _client.rpc<List<dynamic>>(
      Functions.registeredEventUrls,
      params: {'p_creator_id': creatorId, 'p_urls': urls},
    );
    return [for (final r in rows) r as String];
  }

  /// 発信者がアプリの中で開いたページから取り出した部分（[html]）を読ませて、
  /// イベントの下書き（`{ title, performances }`）を受け取る。
  Future<Map<String, dynamic>> readEventUrl(
    String url, {
    required String html,
  }) => _client.functions.invokeResult<Map<String, dynamic>>(
    EdgeFunctions.readEventUrl,
    body: {'url': url, 'html': html},
  );
}
