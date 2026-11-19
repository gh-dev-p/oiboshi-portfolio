import '../../../domain/models/creator.dart';
import '../../../domain/models/event.dart';
import '../../../domain/models/plan_billing.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/report.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../domain/models/sns_service.dart';
import '../../../domain/models/user_settings.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';

/// Model の種類（enum）を、表示言語の文言にする（i18n設計書 6.1）。Model は文言を持たない。
extension L10nLabels on AppLocalizations {
  String sns(SnsService service) => snsServiceName(service.name);

  /// イベントのリンクのサイトの名前。ツイキャスは英語で表記が変わるので、SNS の名前から引く。
  String eventLinkSite(EventLink link) =>
      link.isTwitCasting ? sns(SnsService.twitcasting) : link.siteName;

  String postKind(PostKind kind) => postKindName(kind.name);

  String displayContent(DisplayContent content) =>
      displayContentName(content.name);

  String creatorPlan(CreatorPlan plan) => creatorPlanName(plan.name);

  String displayMode(DisplayMode mode) => displayModeName(mode.name);

  String reportReason(ReportReason reason) => reportReasonName(reason.name);

  String appLanguage(AppLanguage language) => appLanguageName(language.name);

  /// ストアの価格（i18n設計書 6.4）。日本円なら「290円」、ほかの通貨はストアの書式のまま。
  String planPrice(PlanPrice p) =>
      p.isYen ? priceYen('${p.amount.round()}') : p.formatted;

  /// 予定のタイトル。タイトルのない配信は「配信」と出す。
  String scheduleTitle(ScheduleItem item) =>
      item.title.isEmpty ? commonLive : item.title;

  /// 予定の始まりの時刻。終日なら「時刻未定」（イベントの公演で時刻が決まっていない）か「終日」、
  /// そうでなければ開始の時刻（例：21:00）。
  String scheduleStartTime(ScheduleItem item) => item.allDay
      ? (item.timeTbd ? commonTimeTbd : commonAllDay)
      : clockTime(item.startsAt);
}

/// 予定の日時の書き方（例：「10月16日（木）21:00〜22:00」）。日をまたぐ予定は、終了の日付も出す（画面定義書 2.1.5）。
/// 予定の詳細と、イベントの詳細（画面定義書 2.3.2）で使う。
String scheduleDateLabel(ScheduleItem item, AppLocalizations l10n) {
  final end = item.endsAt;
  final date = longDate(item.startsAt, l10n);
  if (item.timeTbd) return l10n.commonScheduleDateTimeTbd(date);
  if (item.allDay) return l10n.commonScheduleDateAllDay(date);
  if (end != null && !isSameDay(item.startsAt, end)) {
    return l10n.commonScheduleDateTimeSpan(
      date,
      clockTime(item.startsAt),
      longDate(end, l10n),
      clockTime(end),
    );
  }
  return l10n.commonScheduleDateTime(
    date,
    clockTime(item.startsAt),
    end == null ? '' : clockTime(end),
  );
}
