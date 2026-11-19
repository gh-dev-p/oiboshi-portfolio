import '../../utils/server_time.dart';
import 'sns_service.dart';

/// 発信者に見せる数（届ける・広める仕様書 4.2.2）。直近30日の合計と、配信・予定ごとの数。数は丸めない。
class ReachOverview {
  const ReachOverview({
    required this.fromDay,
    required this.toDay,
    required this.delivered,
    required this.opened,
    required this.viewed,
    required this.followed,
    required this.unfollowed,
    required this.followers,
    required this.subjects,
  });

  /// 期間（昨日までの30日）。
  final DateTime fromDay;
  final DateTime toDay;

  /// 通知を届けた・通知から来た・予定が見られた・フォローした・解除した（期間の合計）。
  final int delivered;
  final int opened;
  final int viewed;
  final int followed;
  final int unfollowed;

  /// 期間の最後の日のフォロワー数。まだ数えていなければ null。
  final int? followers;

  /// 配信・予定ごとの数（新しい順）。
  final List<ReachSubject> subjects;

  /// `reach_totals` の1行と、`reach_by_subject` の行から作る。
  factory ReachOverview.fromRows(
    Map<String, dynamic> totals,
    List<Map<String, dynamic>> subjects,
  ) => ReachOverview(
    fromDay: DateTime.parse(totals['from_day'] as String),
    toDay: DateTime.parse(totals['to_day'] as String),
    delivered: (totals['delivered'] as num).toInt(),
    opened: (totals['opened'] as num).toInt(),
    viewed: (totals['viewed'] as num).toInt(),
    followed: (totals['followed'] as num).toInt(),
    unfollowed: (totals['unfollowed'] as num).toInt(),
    followers: (totals['followers'] as num?)?.toInt(),
    subjects: subjects.map(ReachSubject.fromRow).toList(),
  );
}

/// 1回の配信・1つの予定の数。
class ReachSubject {
  const ReachSubject({
    required this.subject,
    required this.title,
    required this.startsAt,
    this.allDay = false,
    required this.service,
    required this.delivered,
    required this.opened,
    required this.viewed,
  });

  /// `live:{サービス}:{配信 ID}` か `schedule:{予定の ID}`。
  final String subject;

  /// タイトル。消えた配信・予定なら空。
  final String title;
  final DateTime? startsAt;

  /// 終日・時刻未定の予定か（時刻を出さない）。
  final bool allDay;
  final SnsService? service;
  final int delivered;
  final int opened;
  final int viewed;

  /// 配信（配信開始の通知の対象）か。偽なら予定。
  bool get isLive => subject.startsWith('live:');

  factory ReachSubject.fromRow(Map<String, dynamic> row) => ReachSubject(
    subject: row['subject'] as String,
    title: (row['title'] as String?) ?? '',
    startsAt: parseTime(row['starts_at'] as String?),
    allDay: (row['all_day'] as bool?) ?? false,
    service: SnsService.fromName(row['service'] as String?),
    delivered: (row['delivered'] as num).toInt(),
    opened: (row['opened'] as num).toInt(),
    viewed: (row['viewed'] as num).toInt(),
  );
}
