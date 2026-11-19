import 'package:flutter/foundation.dart';

import '../../../domain/models/reach_overview.dart';
import '../../services/reach/reach_service.dart';
import '../common/error_mapping.dart';

/// 発信者に見せる数（届ける・広める仕様書 4.2.1）の、アプリからの記録。
/// 送れなかったときは、操作を止めずに捨てる（送り直さない）。チームメンバー自身の分は、サーバーが数えない。
class ReachRepository {
  ReachRepository(this._service);

  final ReachService _service;

  /// 通知を押して開いた。配信開始の通知なら [liveService]・[liveId]、予定の事前通知なら [scheduleId] を渡す。
  /// 対象が分からなければ送らない。
  Future<void> recordOpened(
    String creatorId, {
    String? scheduleId,
    String? liveService,
    String? liveId,
  }) {
    final subject = scheduleId != null
        ? 'schedule:$scheduleId'
        : (liveService != null && liveId != null)
        ? 'live:$liveService:$liveId'
        : null;
    if (subject == null) return Future.value();
    return _send(creatorId, 'opened', subject);
  }

  /// 予定の詳細を開いた。
  Future<void> recordViewed(String creatorId, String scheduleId) =>
      _send(creatorId, 'viewed', 'schedule:$scheduleId');

  /// 数の画面に出す、直近30日の合計と配信・予定ごとの数（届ける・広める仕様書 4.2.2）。
  Future<ReachOverview> fetchOverview(String creatorId) => mapErrors(() async {
    final results = await Future.wait([
      _service.fetchTotals(creatorId),
      _service.fetchBySubject(creatorId),
    ]);
    return ReachOverview.fromRows(
      results[0] as Map<String, dynamic>,
      results[1] as List<Map<String, dynamic>>,
    );
  });

  Future<void> _send(String creatorId, String kind, String subject) async {
    try {
      await _service.record(creatorId, kind, subject);
    } catch (e) {
      debugPrint('数の記録を送れない（捨てる）: $e');
    }
  }
}
