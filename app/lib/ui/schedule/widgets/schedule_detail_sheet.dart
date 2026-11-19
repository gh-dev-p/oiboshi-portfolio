import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/external_link_dialog.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/sns_style.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../report/widgets/report_sheet.dart';
import '../view_models/schedule_detail_viewmodel.dart';
import 'schedule_editor.dart';

/// 予定の詳細（シート）（画面定義書 2.1.5）。配信中でない配信と、イベントの公演の内容を見る。
Future<void> showScheduleDetailSheet(
  BuildContext context, {
  required ScheduleItem item,
  required Creator creator,
  bool openCreator = true,
}) => showAppSheet(
  context,
  builder: (_) => ScheduleDetailSheet(
    item: item,
    creator: creator,
    openCreator: openCreator,
    navigator: Navigator.of(context),
  ),
);

class ScheduleDetailSheet extends StatelessWidget {
  const ScheduleDetailSheet({
    super.key,
    required this.item,
    required this.creator,
    required this.openCreator,
    required this.navigator,
  });

  final ScheduleItem item;
  final Creator creator;

  /// 「発信者のページを開く」を出すか（発信者ページから開いたときは出さない）。
  final bool openCreator;

  /// 発信者ページを開く先（タブの中の Navigator）。
  final NavigatorState navigator;

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: ScheduleDetailCard(
        item: item,
        creator: creator,
        onOpenCreator: openCreator
            ? () {
                Navigator.of(context).pop();
                CreatorScreen.open(navigator.context, creator.id);
              }
            : null,
        onEdit: () {
          Navigator.of(context).pop();
          openScheduleEditor(
            navigator.context,
            item: item,
            creatorId: creator.id,
          );
        },
      ),
    );
  }
}

/// 予定の詳細の中身（発信者、タイトルと状態、日時・会場・リンク、ボタン）。
/// 予定の詳細（シート）と、タイムスケジュールの詳細のパネル（画面定義書 2.1.3）で使う。
class ScheduleDetailCard extends ConsumerWidget {
  const ScheduleDetailCard({
    super.key,
    required this.item,
    required this.creator,
    this.onOpenCreator,
    this.onEdit,
  });

  final ScheduleItem item;
  final Creator creator;

  /// 「発信者のページを開く」を押したとき。null なら、ボタンを出さない。
  final VoidCallback? onOpenCreator;

  /// 「編集」を押したとき（イベントの編集の画面を開く）。
  /// 「編集」は、イベントの公演で、自分がオーナーのときだけ出す（画面定義書（スケジュール）2.1.5）。
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(scheduleDetailViewModelProvider(null));
    if (!item.record) {
      ref.watch(
        scheduleViewRecorderProvider((
          creatorId: item.creatorId,
          scheduleId: item.id,
        )),
      );
    }
    final now = DateTime.now();
    final end = item.endsAt;
    final past = item.isPastAt(now);
    final kind = item.isLive ? l10n.scheduleDetailLiveKind : l10n.commonEvent;
    final status = item.isLive
        ? (past ? l10n.scheduleDetailEnded : l10n.scheduleDetailUpcoming)
        : l10n.commonEvent;
    final dateLabel = scheduleDateLabel(item, l10n);
    final ticket = item.ticketUrl;
    final canEdit =
        onEdit != null &&
        item.isEventPerformance &&
        detail.ownedCreatorId == creator.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              AvatarImage(url: creator.avatarUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(kind, style: context.textStyles.hint),
                  ],
                ),
              ),
              PlatformIcon(item.service, size: 26),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scheduleTitle(item),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [StatusChip(status, muted: item.isLive && past)]),
            ],
          ),
        ),
        DetailInfoRow(
          icon: Icons.schedule,
          text: dateLabel,
          // 終了時刻がなければ、長さは出さずに、決まっていないことだけを出す（2026-11-19 本人）。
          sub: !item.allDay && end == null ? l10n.scheduleDetailEndOpen : null,
        ),
        if (item.venue != null)
          DetailInfoRow(icon: Icons.place, text: item.venue!),
        if (ticket != null)
          DetailInfoRow(
            icon: item.isEvent
                ? Icons.confirmation_number_outlined
                : Icons.link,
            text: item.isEvent ? l10n.commonTicket : l10n.commonLink,
            sub: l10n.scheduleDetailLinkHint,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              if (ticket != null) ...[
                PrimaryButton(
                  label: item.isEvent
                      ? l10n.scheduleDetailOpenTicket
                      : l10n.scheduleDetailOpenLink,
                  trailing: item.ticketIsPromotion
                      ? const PrLabel(onDark: true)
                      : null,
                  onPressed: () => confirmAndOpenEventLink(context, ticket),
                ),
                if (onOpenCreator != null) const SizedBox(height: 8),
              ],
              if (onOpenCreator != null)
                ticket != null
                    ? TonalButton(
                        label: l10n.commonOpenCreatorPage,
                        onPressed: onOpenCreator,
                      )
                    : PrimaryButton(
                        label: l10n.commonOpenCreatorPage,
                        onPressed: onOpenCreator,
                      ),
              if (canEdit) ...[
                if (ticket != null || onOpenCreator != null)
                  const SizedBox(height: 8),
                TonalButton(label: l10n.scheduleDetailEdit, onPressed: onEdit),
              ],
              if (detail.canReport(item)) ...[
                const SizedBox(height: 4),
                AppTextButton(
                  label: l10n.scheduleDetailReport,
                  color: c.textSecondary,
                  onPressed: () => showReportSheet(
                    context,
                    ref
                        .read(scheduleDetailViewModelProvider(null).notifier)
                        .reportTarget(item, l10n.scheduleTitle(item)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 詳細の1行。左にアイコン、右に文字と補足。予定の詳細と、イベントの詳細で使う。
class DetailInfoRow extends StatelessWidget {
  const DetailInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.sub,
  });

  final IconData icon;
  final String text;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: c.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub!, style: context.textStyles.hint),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
