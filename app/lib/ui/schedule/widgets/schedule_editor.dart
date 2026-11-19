import 'package:flutter/material.dart';

import '../../../domain/models/schedule_item.dart';
import '../../creator_admin/widgets/event_register_screen.dart';

/// 予定の「編集」の移り先を開く（画面定義書（スケジュール）2.1.5）。
/// 発信者が編集できる予定は、イベントの公演だけ。イベントの編集を開く（タイトルとリンクも一緒に直せるように）。
/// 予定の詳細（シート）・詳細のパネル・イベントの詳細で使う。
Future<void> openScheduleEditor(
  BuildContext context, {
  required ScheduleItem item,
  required String creatorId,
}) async {
  final eventId = item.eventId;
  if (eventId == null) return;
  await EventRegisterScreen.open(
    context,
    creatorId: creatorId,
    eventId: eventId,
  );
}
