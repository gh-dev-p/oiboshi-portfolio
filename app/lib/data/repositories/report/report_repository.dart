import '../../../domain/models/report.dart';
import '../../services/report/report_service.dart';

/// 発信者・イベントの公演・リンク集のリンクの通報（機能仕様書 4.2.7）。
class ReportRepository {
  ReportRepository(this._service);

  final ReportService _service;

  /// 通報を送る。送れなかったときも、例外ではなく [ReportResult.failed] を返す。
  Future<ReportResult> submit(
    ReportTarget target,
    ReportReason reason,
    String detail,
  ) async {
    try {
      final value = await _service.submit(
        creatorId: switch (target) {
          CreatorReportTarget(:final creatorId) => creatorId,
          _ => null,
        },
        scheduleId: switch (target) {
          ScheduleReportTarget(:final scheduleId) => scheduleId,
          _ => null,
        },
        linkId: switch (target) {
          LinkReportTarget(:final linkId) => linkId,
          _ => null,
        },
        reason: reason.serverName,
        detail: detail.trim(),
      );
      return ReportResult.fromServer(value);
    } catch (_) {
      return ReportResult.failed;
    }
  }
}
