import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/external_link_dialog.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/sns_style.dart';
import 'schedule_detail_sheet.dart';
import '../../core/ui/one_line_text.dart';

/// 選んだ日のパネル。予定の行と、実績の行を時刻順に並べる。
class MonthDayPanel extends StatelessWidget {
  const MonthDayPanel({
    super.key,
    required this.day,
    required this.schedules,
    required this.posts,
    required this.creators,
    required this.openCreator,
  });

  final DateTime day;
  final List<ScheduleItem> schedules;
  final List<Post> posts;
  final List<Creator> creators;
  final bool openCreator;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    // 推し全員のカレンダーでは、行ごとに推しのアイコンを出す。1人のカレンダーでは出さない。
    final showAvatar = creators.length > 1;
    final rows = <Widget>[];
    for (final s in schedules) {
      final creator = _findCreator(creators, s.creatorId);
      final title = l10n.scheduleTitle(s);
      rows.add(
        _PanelRow(
          time: l10n.scheduleStartTime(s),
          // 誰の予定かはアイコンで見分ける。読み上げでは名前を読む。
          leading: showAvatar
              ? Semantics(
                  label: creator?.name,
                  child: OshiAvatar(avatarUrl: creator?.avatarUrl, size: 32),
                )
              : null,
          title: title,
          // プラットフォームは右のアイコンで分かるので、名前は出さない。下の段は会場だけ。
          subtitleIcon: s.isLive || s.venue == null ? null : Icons.place,
          subtitle: s.isLive ? null : s.venue,
          trailing: s.isLive
              ? PlatformIcon(s.service, size: 20)
              : s.ticketUrl != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SmallPillButton(
                      label: s.isEvent ? l10n.commonTicket : l10n.commonLink,
                      tonal: true,
                      onPressed: () =>
                          confirmAndOpenEventLink(context, s.ticketUrl!),
                    ),
                    if (s.ticketIsPromotion) ...[
                      const SizedBox(height: 4),
                      const PrLabel(),
                    ],
                  ],
                )
              : PlatformIcon(s.service, size: 20),
          onTap: creator == null
              ? null
              : () => showScheduleDetailSheet(
                  context,
                  item: s,
                  creator: creator,
                  openCreator: openCreator,
                ),
        ),
      );
    }
    if (posts.isNotEmpty) {
      final sources = {for (final p in posts) p.source}.toList();
      final postCreators = [
        for (final id in {for (final p in posts) p.creatorId})
          ?_findCreator(creators, id),
      ];
      rows.add(
        _PanelRow(
          time: l10n.commonPost,
          leading: showAvatar && postCreators.isNotEmpty
              ? _AvatarStack(creators: postCreators)
              : null,
          title: l10n.scheduleCalendarDayPosts,
          subtitle: l10n.schedulePostCount(posts.length),
          // 各社のロゴは重ねない（ブランドガイドライン。tech-risks.md 2.21）。
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < sources.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                PlatformIcon(sources[i], size: 20),
              ],
            ],
          ),
        ),
      );
    }
    return SurfacePanel(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
            child: Text(
              longDate(day, l10n),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Text(
                l10n.scheduleDayEmpty,
                style: context.textStyles.note,
              ),
            ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(color: c.divider, indent: 16, endIndent: 16),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// 発信者 ID で引く。
Creator? _findCreator(List<Creator> creators, String id) =>
    creators.where((c) => c.id == id).firstOrNull;

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.time,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.leading,
    this.subtitleIcon,
    this.onTap,
  });

  final String time;

  /// 時刻とタイトルのあいだに出す、推しのアイコン。
  final Widget? leading;
  final String title;
  final String? subtitle;
  final IconData? subtitleIcon;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 時刻は折り返さない。入りきらない文字の大きさでは、縮めて1行に収める。
            SizedBox(
              width: 48,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: OneLineText(
                  time,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineText(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (subtitleIcon != null) ...[
                          Icon(subtitleIcon, size: 14, color: c.textSecondary),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: OneLineText(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// 投稿の行の推しのアイコン。2人までを、少しずらして重ねる。
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.creators});

  final List<Creator> creators;

  static const _size = 32.0;
  static const _offset = 14.0;

  @override
  Widget build(BuildContext context) {
    final shown = creators.take(2).toList();
    return SizedBox(
      width: _size + _offset * (shown.length - 1),
      height: _size,
      child: Stack(
        children: [
          for (var i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: _offset * i,
              child: OshiAvatar(
                avatarUrl: shown[i].avatarUrl,
                size: _size,
                borderColor: context.colors.surface,
                borderWidth: 1.5,
              ),
            ),
        ],
      ),
    );
  }
}
