import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/event.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/event_panel.dart';
import '../../core/ui/external_link_dialog.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../report/widgets/report_sheet.dart';
import '../view_models/schedule_detail_viewmodel.dart';
import 'schedule_detail_sheet.dart';
import 'schedule_editor.dart';
import '../../core/ui/viewer_aware_header.dart';

/// イベントの詳細（画面定義書（スケジュール）2.3.2）。日付とタイトル、発信者、日時・会場、
/// 「チケットサイトで見る」。チケットの販売の状況は出さない（決定事項 1）。
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({
    super.key,
    required this.item,
    required this.creator,
    this.openCreator = true,
  });

  final ScheduleItem item;
  final Creator creator;

  /// 発信者の行を押して、発信者ページを開けるか（発信者ページから開いたときは開けない）。
  final bool openCreator;

  /// 開いたタブの中で、いまの画面の上に重ねる（画面定義書 5.1.8）。
  static Future<void> open(
    BuildContext context, {
    required ScheduleItem item,
    required Creator creator,
    bool openCreator = true,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => EventDetailScreen(
        item: item,
        creator: creator,
        openCreator: openCreator,
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(scheduleDetailViewModelProvider(item.eventId));
    // 終わったかは、イベント一覧と同じ判定（画面定義書（スケジュール）2.3.2）。
    final past = item.hasEndedAt(DateTime.now());
    // イベントのリンク（何本でも）。イベントの表にないもの（古い予定）は、予定の行のリンクを出す。
    final eventLinks = detail.eventLinks;
    final ticket = item.ticketUrl;
    final links =
        eventLinks ??
        [
          if (ticket != null)
            EventLink(url: ticket, isPromotion: item.ticketIsPromotion),
        ];
    final owned = detail.ownedCreatorId == creator.id;
    final venue = item.venue?.trim() ?? '';
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.commonEventsTitle),
      body: ListView(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          // 上の段：日付のブロックとタイトル。
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventDateTile(start: item.startsAt.toLocal()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.scheduleTitle(item),
                        style: TextStyle(
                          fontSize: 20,
                          height: 28 / 20,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      if (past) ...[
                        const SizedBox(height: 8),
                        StatusChip(l10n.scheduleDetailEnded, muted: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          _CreatorRow(
            creator: creator,
            onTap: openCreator
                ? () => CreatorScreen.open(context, creator.id)
                : null,
          ),
          const SizedBox(height: 4),
          DetailInfoRow(
            icon: Icons.schedule,
            text: scheduleDateLabel(item, l10n),
            // 終了時刻がなければ、長さは出さずに、決まっていないことだけを出す（2026-11-19 本人）。
            sub: !item.allDay && item.endsAt == null
                ? l10n.scheduleDetailEndOpen
                : null,
          ),
          if (venue.isNotEmpty) DetailInfoRow(icon: Icons.place, text: venue),
          if (links.isNotEmpty) SectionLabel(l10n.commonTicket),
          Padding(
            padding: EdgeInsets.fromLTRB(16, links.isNotEmpty ? 0 : 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, link) in links.indexed) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _LinkButton(
                    label: l10n.eventDetailOpenSite(l10n.eventLinkSite(link)),
                    promotion: link.isPromotion,
                    primary: i == 0,
                    onPressed: () => confirmAndOpenEventLink(context, link.url),
                  ),
                ],
                if (links.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.scheduleDetailLinkHint,
                    textAlign: TextAlign.center,
                    style: context.textStyles.hint,
                  ),
                ],
                if (owned && item.isEventPerformance) ...[
                  const SizedBox(height: 12),
                  TonalButton(
                    label: l10n.scheduleDetailEdit,
                    onPressed: () => openScheduleEditor(
                      context,
                      item: item,
                      creatorId: creator.id,
                    ),
                  ),
                ],
                if (detail.canReport(item)) ...[
                  const SizedBox(height: 8),
                  AppTextButton(
                    label: l10n.scheduleDetailReport,
                    color: c.textSecondary,
                    onPressed: () => showReportSheet(
                      context,
                      ref
                          .read(
                            scheduleDetailViewModelProvider(
                              item.eventId,
                            ).notifier,
                          )
                          .reportTarget(item, l10n.scheduleTitle(item)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 発信者の行。アイコンと名前。[onTap] があれば、右向きの矢印を出して押せるようにする。
class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.creator, required this.onTap});

  final Creator creator;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            AvatarImage(url: creator.avatarUrl, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: OneLineText(
                creator.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 22, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// チケットサイトのボタン。1本目は目立つボタン、2本目からは薄いボタン。広告なら「PR」を添える。
class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.promotion,
    required this.primary,
    required this.onPressed,
  });

  final String label;
  final bool promotion;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return PrimaryButton(
        label: label,
        trailing: promotion ? const PrLabel(onDark: true) : null,
        onPressed: onPressed,
      );
    }
    final c = context.colors;
    return SizedBox(
      height: 50,
      child: Material(
        color: c.tonal,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: OneLineText(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (promotion) ...[const SizedBox(width: 8), const PrLabel()],
            ],
          ),
        ),
      ),
    );
  }
}
