import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../../utils/open_url.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../core/ui/link_text.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/sns_style.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../../home/widgets/home_tabs.dart';
import '../../report/widgets/report_sheet.dart';
import '../../share/widgets/share_link_screen.dart';
import '../../schedule/widgets/month_calendar_screen.dart';
import '../view_models/creator_viewmodel.dart';

// 発信者ページで共有する小部品。

/// フォロワー数の合計と、SNS ごとのフォロワー数のチップ。
class CreatorFollowerCounts extends StatelessWidget {
  const CreatorFollowerCounts({super.key, required this.creator});

  final Creator creator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 数を上に大きく、その下に「合計フォロワー」を小さく積む（Instagram・X のプロフィールと同じ形。2026-11-19 本人）。
        Text(
          compactCount(creator.totalFollowers!, l10n),
          style: TextStyle(
            fontSize: 20,
            height: 24 / 20,
            fontWeight: FontWeight.w700,
            color: c.textPrimary,
          ),
        ),
        Text(
          l10n.creatorTotalFollowers,
          style: TextStyle(fontSize: 13, height: 18 / 13, color: c.textMuted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in creator.followerCounts.entries)
              CreatorSnsChip(
                service: entry.key,
                count: entry.value,
                // 確認が外れてから、数が消えるまで（最大1時間）は、開く先がないので押せない。
                onTap: switch (creator.accounts[entry.key]) {
                  final account? => () => openUrl(
                    entry.key.profileUrl(account),
                  ),
                  null => null,
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// 発信者ページのプロフィール文（画面定義書 2.4.1）。1行目だけを出し、2行目からは折りたたむ。
/// 1行に収まらないとき、または改行があるときは、1行目の終わりを「…」にして「もっと見る」を出す。
/// 開くと全文（リンクは押せる）と「閉じる」を出す。
class CreatorBio extends StatefulWidget {
  const CreatorBio(this.bio, {super.key, required this.style});

  final String bio;
  final TextStyle style;

  @override
  State<CreatorBio> createState() => _CreatorBioState();
}

class _CreatorBioState extends State<CreatorBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bio = widget.bio.trim();
    final newline = bio.indexOf('\n');
    final firstLine = newline < 0 ? bio : bio.substring(0, newline).trimRight();
    return LayoutBuilder(
      builder: (context, constraints) {
        final folds =
            newline >= 0 ||
            (TextPainter(
              text: TextSpan(
                text: firstLine,
                style: DefaultTextStyle.of(context).style.merge(widget.style),
              ),
              maxLines: 1,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth)).didExceedMaxLines;
        if (!folds) return LinkText(bio, style: widget.style);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_expanded)
              LinkText(bio, style: widget.style)
            else
              LinkText(
                // 改行で切ったときも、続きがあることが分かるように「…」を付ける。
                newline >= 0 ? '$firstLine…' : firstLine,
                style: widget.style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _expanded ? l10n.creatorBioCollapse : l10n.creatorBioExpand,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// SNS ごとのフォロワー数のチップ。押すと、その SNS のプロフィールを開く。
class CreatorSnsChip extends StatelessWidget {
  const CreatorSnsChip({
    super.key,
    required this.service,
    required this.count,
    required this.onTap,
  });

  final SnsService service;
  final int count;

  /// 押したとき。null なら押せない。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
        decoration: BoxDecoration(
          border: Border.all(color: c.outline),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformIcon(service, size: 18),
            const SizedBox(width: 6),
            Text(
              compactCount(count, AppLocalizations.of(context)!),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 発信者ページの、フォロー中のときのベルのボタン（画面定義書（ファン向け）2.4.1）。
/// 通知オンは塗ったベル、オフは斜線の入ったベル。押すと、シートで「通知をオンにする／オフにする」と「フォローをやめる」を選ぶ。
/// 失敗したら、スナックバーを出す。
class CreatorBellButton extends StatelessWidget {
  const CreatorBellButton({super.key, required this.notify, required this.vm});

  final bool notify;
  final CreatorViewModel vm;

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showAppSheet<_BellAction>(
      context,
      builder: (context) => AppSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsRow(
              icon: null,
              label: notify
                  ? l10n.creatorBellNotifyOff
                  : l10n.creatorBellNotifyOn,
              showChevron: false,
              onTap: () => Navigator.of(context).pop(_BellAction.notify),
            ),
            SettingsRow(
              icon: null,
              label: l10n.creatorBellUnfollow,
              showChevron: false,
              onTap: () => Navigator.of(context).pop(_BellAction.unfollow),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _BellAction.notify:
        if (!await vm.toggleNotify() && context.mounted) {
          showAppSnackBar(context, l10n.commonNotificationSettingChangeFailed);
        }
      case _BellAction.unfollow:
        if (!await vm.toggleFollow() && context.mounted) {
          showAppSnackBar(context, l10n.commonFollowChangeFailed);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      icon: notify ? Icons.notifications : Icons.notifications_off,
      size: 36,
      iconSize: 22,
      tooltip: AppLocalizations.of(context)!.creatorBellMenu,
      onPressed: () => _open(context),
    );
  }
}

enum _BellAction { notify, unfollow }

/// 月のカレンダーを開くボタン。これからの予定があれば、色を変える。
class CreatorCalendarButton extends StatelessWidget {
  const CreatorCalendarButton({
    super.key,
    required this.creator,
    required this.hasUpcoming,
    required this.size,
  });

  final Creator creator;
  final bool hasUpcoming;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CircleIconButton(
      icon: Icons.calendar_month,
      size: size,
      iconSize: size == 36 ? 20 : 24,
      background: hasUpcoming ? c.upcomingFill : null,
      foreground: hasUpcoming ? c.upcomingIcon : null,
      tooltip: AppLocalizations.of(context)!.creatorMonthCalendar,
      // 発信者ページから開くので、予定の詳細から同じ発信者ページを重ねない。
      // 発信者ページの一部として、発信者ページと同じタブ（ふつうは推しのタブ）の中で開く（画面定義書 5.1.8）。
      onPressed: () => MonthCalendarScreen.open(
        context,
        creators: [creator],
        openCreator: false,
        tab: HomeTabs.tabOf(context) ?? HomeTab.oshi,
      ),
    );
  }
}

/// メニューの項目。
enum _CreatorMenuAction { shareLink, report, hide }

/// 発信者ページのメニュー（「…」）。「リンクを共有」「通報する」「この発信者を表示しない」を出す（画面定義書（ファン向け）2.4.1）。
/// 自分がオーナーの発信者（[ownPage]）では、「リンクを共有」だけを出す。
/// 【仮】「リンクを共有」の置き場と見た目は あとで決める。
class CreatorMenuButton extends ConsumerWidget {
  const CreatorMenuButton({
    super.key,
    required this.creator,
    required this.vm,
    this.ownPage = false,
    this.color,
  });

  final Creator creator;
  final CreatorViewModel vm;

  /// 自分がオーナーの発信者のページか（[CreatorPageState.showMenu] が偽）。
  final bool ownPage;

  /// アイコンの色。null なら、文字の色の薄いもの。
  final Color? color;

  Future<void> _hide(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.creatorHideConfirmTitle(creator.name),
      message: l10n.creatorHideConfirmMessage,
      confirmLabel: l10n.creatorHideConfirmAction,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await ref.read(loadingOverlayProvider.notifier).run(vm.hide);
    if (!context.mounted) return;
    if (!ok) {
      showAppSnackBar(context, l10n.creatorHideFailed);
      return;
    }
    // 前の画面に戻ってから、スナックバーを出す（画面の外の ScaffoldMessenger に出す）。
    showAppSnackBar(context, l10n.creatorHidden);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    return PopupMenuButton<_CreatorMenuAction>(
      tooltip: l10n.creatorMenu,
      icon: Icon(Icons.more_horiz, color: color ?? c.textMuted),
      onSelected: (action) {
        switch (action) {
          case _CreatorMenuAction.shareLink:
            // 自分（チーム）の発信者ページなら、発信者の側の文で誘う。
            openShareLinkScreen(context, creator.id, asCreator: ownPage);
          case _CreatorMenuAction.report:
            final target = vm.reportTarget;
            if (target != null) showReportSheet(context, target);
          case _CreatorMenuAction.hide:
            _hide(context, ref);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CreatorMenuAction.shareLink,
          child: Text(l10n.shareLinkAction),
        ),
        if (!ownPage) ...[
          PopupMenuItem(
            value: _CreatorMenuAction.report,
            child: Text(l10n.creatorReport),
          ),
          PopupMenuItem(
            value: _CreatorMenuAction.hide,
            child: Text(l10n.creatorHide),
          ),
        ],
      ],
    );
  }
}
