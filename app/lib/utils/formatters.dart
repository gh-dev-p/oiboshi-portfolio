import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

/// 日付・時刻・数の表記（i18n設計書 7章）。表示言語は [AppLocalizations] で受け取る。
/// 日本語は日本で一般的な書式をここで指定し、英語は `intl` の表示言語の書式を使う。

bool _isJa(AppLocalizations l10n) => l10n.localeName.startsWith('ja');

const _jaWeekdays = ['月', '火', '水', '木', '金', '土', '日'];

/// 曜日の短い表記を、月曜から日曜の順に並べたもの（例：月、Mon）。
List<String> weekdayLabels(AppLocalizations l10n) => _isJa(l10n)
    ? _jaWeekdays
    : [
        // 2024-01-01 は月曜日。
        for (var i = 0; i < 7; i++)
          DateFormat.E(l10n.localeName).format(DateTime(2024, 1, 1 + i)),
      ];

/// 曜日の短い表記（例：月、Mon）。
String weekdayLabel(DateTime time, AppLocalizations l10n) =>
    weekdayLabels(l10n)[time.weekday - 1];

/// 「3分前」「2日前」のような相対時刻。30日以上前は日付。
String relativeTime(
  DateTime time, {
  required DateTime now,
  required AppLocalizations l10n,
}) {
  final diff = now.difference(time);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 30) return l10n.timeDaysAgo(diff.inDays);
  final t = time.toLocal();
  return _isJa(l10n)
      ? '${t.year}/${t.month}/${t.day}'
      : DateFormat.yMd(l10n.localeName).format(t);
}

/// 配信の経過時間（例: 1:05:09、05:09）。
String elapsed(DateTime since, {required DateTime now}) {
  final d = now.difference(since);
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

/// 時刻（例: 09:05）。タイムスケジュールの目盛りと揃えるため、どの言語でも24時間表記。
String clockTime(DateTime time) {
  final t = time.toLocal();
  return clockOfDay(t.hour, t.minute);
}

/// 時と分の時刻（例: 09:05）。どの言語でも24時間表記（[clockTime] と同じ）。入力欄の時刻（`TimeOfDay`）にも使う。
String clockOfDay(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

/// 日付（例: 10/16）。どの言語でも月/日。
String monthDay(DateTime time) => '${time.month}/${time.day}';

/// 曜日つきの日付（例: 10/12(日)、Sun 10/12）。
String monthDayWeekday(DateTime time, AppLocalizations l10n) => _isJa(l10n)
    ? '${monthDay(time)}(${weekdayLabel(time, l10n)})'
    : '${weekdayLabel(time, l10n)} ${monthDay(time)}';

/// 月の短い表記（例: 11月、Nov）。イベント一覧の日付のブロックで使う。
String monthLabel(DateTime time, AppLocalizations l10n) => _isJa(l10n)
    ? '${time.month}月'
    : DateFormat.MMM(l10n.localeName).format(time);

/// 年月（例: 2026年10月、October 2026）。
String yearMonth(DateTime time, AppLocalizations l10n) => _isJa(l10n)
    ? '${time.year}年${time.month}月'
    : DateFormat.yMMMM(l10n.localeName).format(time);

/// 年月日（例: 2026年11月14日、Nov 14, 2026）。
String fullDate(DateTime time, AppLocalizations l10n) => _isJa(l10n)
    ? '${time.year}年${time.month}月${time.day}日'
    : DateFormat.yMMMd(l10n.localeName).format(time);

/// 月日と曜日（例: 10月16日（木）、Thu, Oct 16）。
String longDate(DateTime time, AppLocalizations l10n) => _isJa(l10n)
    ? '${time.month}月${time.day}日（${weekdayLabel(time, l10n)}）'
    : DateFormat.MMMEd(l10n.localeName).format(time);

/// 予定の日時。今日は「今日 21:00」、明日は「明日 12:00」、それ以外は「10/16 22:00」。
String scheduleLabel(
  DateTime time, {
  required DateTime now,
  required AppLocalizations l10n,
}) {
  final t = time.toLocal();
  final days = dateOnly(t).difference(dateOnly(now.toLocal())).inDays;
  final day = switch (days) {
    0 => l10n.commonToday,
    1 => l10n.commonTomorrow,
    _ => monthDay(t),
  };
  return '$day ${clockTime(t)}';
}

/// 3桁区切りの数値（例: 1,234）。
String withCommas(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// 予定までの残り時間（例: あと3時間 / 明日 / 3日後）。
String untilLabel(
  DateTime time, {
  required DateTime now,
  required AppLocalizations l10n,
}) {
  final diff = time.difference(now);
  if (diff.isNegative) return l10n.timeStarted;
  if (diff.inMinutes < 60) return l10n.timeSoon;
  final days = dateOnly(
    time.toLocal(),
  ).difference(dateOnly(now.toLocal())).inDays;
  if (days == 0) return l10n.timeHoursLeft(diff.inHours);
  if (days == 1) return l10n.commonTomorrow;
  return l10n.timeDaysLater(days);
}

/// 短くした数値（再生回数などの表記）。日本語は1万以上を「1.2万」、1億以上を「1.2億」、英語は「12K」の形。
/// 日本語で小数第1位が 0 なら省く（「60万」「1億」。機能仕様書 4.2.5）。
String compactCount(int n, AppLocalizations l10n) {
  if (!_isJa(l10n)) {
    return n < 1000
        ? withCommas(n)
        : NumberFormat.compact(locale: l10n.localeName).format(n);
  }
  if (n < 10000) return withCommas(n);
  // 整数で切り捨てる（浮動小数の誤差で、桁がずれないように）。
  if (n >= 100000000) return _tenths(n ~/ 10000000, '億');
  if (n >= 1000000) return '${n ~/ 10000}万';
  return _tenths(n ~/ 1000, '万');
}

/// 10分の1の単位の数 [tenths] を、「1.2万」の形にする。小数第1位が 0 なら省く。
String _tenths(int tenths, String unit) {
  return tenths % 10 == 0
      ? '${tenths ~/ 10}$unit'
      : '${tenths ~/ 10}.${tenths % 10}$unit';
}

/// 時刻を除いた日付。
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// 同じ日か。
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
