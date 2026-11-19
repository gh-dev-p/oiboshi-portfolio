/// 通報の理由（機能仕様書 4.2.7、`reports.reason`）。
/// 画面に出す名前は、View で `AppLocalizations.reportReasonName` から引く。
enum ReportReason {
  impersonation('impersonation'),
  inappropriate('inappropriate'),
  dangerousLink('dangerous_link'),
  other('other');

  const ReportReason(this.serverName);

  /// サーバーに渡す名前。
  final String serverName;
}

/// 通報の対象。発信者・イベントの公演・リンク集のリンクのどれか。
sealed class ReportTarget {
  const ReportTarget();

  /// シートの見出しの下に出す名前（発信者の名前・予定のタイトル・リンクの題名）。
  String get label;
}

/// 発信者の通報。
class CreatorReportTarget extends ReportTarget {
  const CreatorReportTarget({required this.creatorId, required this.name});

  final String creatorId;
  final String name;

  @override
  String get label => name;
}

/// イベントの公演の通報。発信者は、サーバーが予定から引く。
class ScheduleReportTarget extends ReportTarget {
  const ScheduleReportTarget({required this.scheduleId, required this.title});

  final String scheduleId;
  final String title;

  @override
  String get label => title;
}

/// リンク集のリンクの通報（届ける・広める仕様書 4.6.4）。発信者は、サーバーがリンクから引く。
class LinkReportTarget extends ReportTarget {
  const LinkReportTarget({required this.linkId, required this.title});

  final String linkId;
  final String title;

  @override
  String get label => title;
}

/// 通報の結果。
enum ReportResult {
  /// 受け付けた。
  submitted,

  /// 24時間のうちに、同じ対象を通報済み。
  duplicate,

  /// 送れなかった（対象が見つからないときを含む）。
  failed;

  /// サーバー（Edge Function `submit-report`）の結果から引く。
  static ReportResult fromServer(String? value) => switch (value) {
    'submitted' => submitted,
    'duplicate' => duplicate,
    _ => failed,
  };
}
