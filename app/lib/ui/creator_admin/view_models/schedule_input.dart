import 'package:flutter/material.dart' show TimeOfDay;

import '../../../domain/models/event.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../utils/formatters.dart';
import '../../../utils/text_limits.dart';

/// イベント（公演）の、日時の入力欄の値。
typedef ScheduleTimes = ({
  DateTime date,
  bool allDay,
  TimeOfDay? start,
  TimeOfDay? end,
});

/// 入っている予定から、日時の入力欄の初期値を作る（編集のとき）。
ScheduleTimes scheduleTimesOf(ScheduleItem item) {
  final start = item.startsAt.toLocal();
  final end = item.endsAt?.toLocal();
  return (
    date: dateOnly(start),
    allDay: item.allDay,
    start: item.allDay ? null : TimeOfDay.fromDateTime(start),
    end: item.allDay || end == null ? null : TimeOfDay.fromDateTime(end),
  );
}

/// 日時の入力から、開始と終了を組み立てる。終日なら、その日の始まりで、終了はない。
/// 終了が開始より前（同じ時刻を含む）なら、翌日の時刻とみなす。終日でなければ、[start] は必須。
({DateTime startsAt, DateTime? endsAt}) startEndOf({
  required DateTime date,
  required bool allDay,
  required TimeOfDay? start,
  required TimeOfDay? end,
}) {
  final startsAt = allDay
      ? dateOnly(date)
      : DateTime(date.year, date.month, date.day, start!.hour, start.minute);
  DateTime? endsAt;
  if (!allDay && end != null) {
    endsAt = DateTime(date.year, date.month, date.day, end.hour, end.minute);
    if (!endsAt.isAfter(startsAt)) {
      endsAt = endsAt.add(const Duration(days: 1));
    }
  }
  return (startsAt: startsAt, endsAt: endsAt);
}

/// 日付の選択の範囲（今日の365日前から、2年後まで）。入っている日付 [date] が外にあれば、そこまで広げる
/// （範囲の外の日付で日付の選択を開くと落ちるため）。
(DateTime, DateTime) scheduleDateRange(DateTime? date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  var first = dateOnly(today.subtract(const Duration(days: 365)));
  var last = dateOnly(today.add(const Duration(days: 365 * 2)));
  if (date != null && date.isBefore(first)) first = dateOnly(date);
  if (date != null && date.isAfter(last)) last = dateOnly(date);
  return (first, last);
}

/// 予定・イベントのタイトルの上限（見た目の1文字（書記素）で数えた文字数）。
const maxScheduleTitleLength = 200;

/// タイトルが空か。
bool scheduleTitleMissing(String title) => title.trim().isEmpty;

/// タイトルが、見た目の1文字（書記素）で [maxScheduleTitleLength] 文字を超えるか。
bool scheduleTitleTooLong(String title) =>
    graphemeLength(title.trim()) > maxScheduleTitleLength;

/// リンクが入っていて、`https://` で始まる URL でないか（機能仕様書 4.5.2）。
bool scheduleLinkInvalid(String link) {
  final l = link.trim();
  return l.isNotEmpty && !isHttpsUrl(l);
}

/// 保存の前の確かめ。必須の項目・タイトルの長さ・リンクの順に確かめ、最初に見つかった理由を返す。なければ null。
E? checkScheduleInput<E>({
  required bool valid,
  required bool titleTooLong,
  required bool linkInvalid,
  required E requiredMissing,
  required E tooLong,
  required E badLink,
}) {
  if (!valid) return requiredMissing;
  if (titleTooLong) return tooLong;
  if (linkInvalid) return badLink;
  return null;
}

/// イベントを保存する（[save]）。保存できたら null、できなければ理由（`EventSaveException` の理由。
/// ほかの例外は [EventSaveError.failed]）。
Future<EventSaveError?> saveEventOrError(
  Future<Object?> Function() save,
) async {
  try {
    await save();
    return null;
  } on EventSaveException catch (e) {
    return e.error;
  } catch (_) {
    return EventSaveError.failed;
  }
}
