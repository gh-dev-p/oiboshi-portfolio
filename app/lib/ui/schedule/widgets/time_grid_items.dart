import 'package:flutter/material.dart';

import '../../../domain/models/schedule_layout.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/one_line_text.dart';

/// 予定のブロック。プラットフォームの色で見分け、終わった予定は薄く、配信中は濃くして影を付ける。
class TimeGridBlock extends StatelessWidget {
  const TimeGridBlock({
    super.key,
    required this.block,
    required this.expanded,
    required this.half,
    required this.now,
    required this.onTap,
  });

  final ScheduleBlock block;
  final bool expanded;
  final bool half;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final title = block.title.isEmpty ? l10n.commonLive : block.title;
    final color = SnsStyle.colorOf(context, block.service);
    final past = block.isPastAt(now);
    final live = block.isLiveNow;
    final top = live ? 0.26 : 0.20;
    final mid = live ? 0.13 : (block.openEnded ? 0.12 : 0.10);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: top),
        color.withValues(alpha: mid),
        if (block.openEnded) color.withValues(alpha: 0),
      ],
      stops: block.openEnded ? const [0, 0.5, 1] : null,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight <= 14;
        // 拡大で、2行のタイトルが入らない短いブロックは、アイコンと1行のタイトルだけにする。
        // 半分の幅は、アイコンの下に題名を置くので、1行の題名にも 52 は要る。
        final tight = expanded && constraints.maxHeight < (half ? 52 : 44);
        final radius = short ? 6.0 : 12.0;
        final timeLabel = block.openEnded
            ? l10n.scheduleOpenEndedTime(clockTime(block.start))
            : '${clockTime(block.start)}–${clockTime(block.end)}';
        return Opacity(
          opacity: past ? 0.5 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: live
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                padding: expanded
                    ? EdgeInsets.fromLTRB(
                        half ? 7 : 9,
                        tight ? 3 : 8,
                        half ? 4 : 8,
                        tight ? 3 : 6,
                      )
                    : EdgeInsets.only(top: short ? 1 : 6),
                clipBehavior: Clip.antiAlias,
                child: tight
                    ? Row(
                        children: [
                          PlatformIcon(block.service, size: 16),
                          SizedBox(width: half ? 4 : 6),
                          Expanded(
                            child: OneLineText(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (half) ...[
                            PlatformIcon(block.service, size: 16),
                            const SizedBox(height: 4),
                            // 半分の幅では、アイコンの下に題名を置く。2行が入らない高さなら1行にする。
                            Text(
                              title,
                              maxLines: constraints.maxHeight >= 70 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.textPrimary,
                              ),
                            ),
                          ] else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PlatformIcon(block.service, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          // 半分の幅では、アイコンの下に題名が2行入るので、そのぶん高さに余裕があるときだけ時刻を出す
                          // （入りきらずにはみ出さないように）。
                          if (constraints.maxHeight > (half ? 88 : 48)) ...[
                            const SizedBox(height: 3),
                            Text(
                              timeLabel,
                              maxLines: half ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                          if (block.service != null &&
                              constraints.maxHeight > (half ? 100 : 70))
                            Text(
                              l10n.sns(block.service!),
                              style: TextStyle(
                                fontSize: 10,
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: PlatformIcon(
                          block.service,
                          size: short ? 10 : 16,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 投稿チップ、または「+N」。
class TimeGridClusterChip extends StatelessWidget {
  const TimeGridClusterChip({
    super.key,
    required this.cluster,
    required this.expanded,
    required this.past,
    required this.onTap,
  });

  final PostCluster cluster;
  final bool expanded;
  final bool past;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final post = cluster.posts.first;
    final color = cluster.isGroup
        ? SnsStyle.generic
        : SnsStyle.colorOf(context, post.source);
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: cluster.isGroup
            ? [color.withValues(alpha: 0.22), color.withValues(alpha: 0.12)]
            : [color.withValues(alpha: 0.30), color.withValues(alpha: 0.18)],
      ),
      borderRadius: BorderRadius.circular(expanded ? 11 : 9),
      border: Border.all(color: c.background, width: 1.5),
    );
    final textStyle = TextStyle(
      fontSize: cluster.isGroup ? (expanded ? 13 : 11) : 11,
      height: 14 / 11,
      fontWeight: cluster.isGroup ? FontWeight.w700 : FontWeight.w500,
      color: c.textPrimary,
    );
    final services = cluster.services;
    final Widget child;
    if (cluster.isGroup && services.length > 1) {
      // SNS が混ざった「+N」：含まれる SNS の小さなアイコンを、重ねずに並べる。
      child = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 6 : 2,
          vertical: expanded ? 6 : 0,
        ),
        child: _MixedGroupLabel(
          services: services,
          count: '+${cluster.posts.length}',
          style: textStyle,
          iconSize: expanded ? 14 : 12,
        ),
      );
    } else if (!expanded) {
      // 置かれた枠（重ならなければ列の幅いっぱい）に広げ、真ん中に出す。
      child = Center(
        child: cluster.isGroup
            ? Text('+${cluster.posts.length}', style: textStyle)
            : PlatformIcon(post.source, size: 16),
      );
    } else if (cluster.isGroup) {
      child = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlatformIcon(post.source, size: 16),
            const SizedBox(width: 3),
            Text('+${cluster.posts.length}', style: textStyle),
          ],
        ),
      );
    } else {
      // 高さに入るだけ、本文を出す。
      child = LayoutBuilder(
        builder: (context, constraints) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlatformIcon(post.source, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.text.trim().isEmpty
                      ? l10n.postKind(post.kind)
                      : post.text.trim(),
                  maxLines: ((constraints.maxHeight - 8) / 14).floor().clamp(
                    1,
                    8,
                  ),
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final chip = Opacity(
      opacity: past && !cluster.isGroup ? 0.75 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(expanded ? 11 : 9),
          child: DecoratedBox(decoration: decoration, child: child),
        ),
      ),
    );
    if (!cluster.isGroup) return chip;
    // 「+N」の読み上げに、件数と、含まれる SNS を入れる。
    return Semantics(
      label: l10n.schedulePostsGroupSemantics(
        cluster.posts.length,
        services.map(l10n.sns).join(l10n.commonListSeparator),
      ),
      button: true,
      excludeSemantics: true,
      child: chip,
    );
  }
}

/// SNS が混ざった「+N」の中身。含まれる SNS のアイコンを重ねずに並べ、その右に件数を出す。
/// 幅に入りきらないときは、入るだけのアイコンを出す。2つも入らないときは、件数だけを出す
/// （1つだけ出すと、SNS が1種類の「+N」と見分けられないため）。
class _MixedGroupLabel extends StatelessWidget {
  const _MixedGroupLabel({
    required this.services,
    required this.count,
    required this.style,
    required this.iconSize,
  });

  final List<SnsService> services;
  final String count;
  final TextStyle style;
  final double iconSize;

  /// アイコンどうしの間。各社のロゴは重ねない（ブランドガイドライン。tech-risks.md 2.21）。
  static const _spacing = 1.0;

  /// アイコンと件数の間。
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final step = iconSize + _spacing;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: count, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final room = constraints.maxWidth - painter.width - _gap;
        painter.dispose();
        final fit = room < iconSize
            ? 0
            : ((room - iconSize) / step).floor() + 1;
        final shown = fit < 2 ? 0 : fit.clamp(0, services.length);
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (shown > 0) ...[
              for (var i = 0; i < shown; i++) ...[
                if (i > 0) const SizedBox(width: _spacing),
                PlatformIcon(services[i], size: iconSize),
              ],
              const SizedBox(width: _gap),
            ],
            Flexible(
              child: OneLineText(
                count,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: style,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 詳細のパネルで選んでいる要素を目立たせる（画面定義書 2.1.3）。
/// 選んだ要素は、少し大きくし、プラットフォームの色の淡い影で浮かせる。ほかの要素は薄くする。
/// 選んでいないときも同じ形の木にして、選び直したときに、作り直さず、なめらかに移るようにする。
class FocusEffect extends StatelessWidget {
  const FocusEffect({
    super.key,
    required this.selectedKey,
    required this.itemKey,
    required this.color,
    required this.child,
  });

  /// 選んでいる要素。null なら、何も選んでいない（すべて通常の見え方）。
  final String? selectedKey;
  final String itemKey;
  final Color color;
  final Widget child;

  static const _duration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final selected = selectedKey == itemKey;
    final dimmed = selectedKey != null && !selected;
    return AnimatedOpacity(
      duration: _duration,
      opacity: dimmed ? 0.3 : 1,
      child: AnimatedScale(
        duration: _duration,
        curve: Curves.easeOutCubic,
        scale: selected ? 1.04 : 1,
        child: AnimatedContainer(
          duration: _duration,
          // 要素は半透明なので、選んだときは下に地の色を敷き、影が中まで透けないようにする。
          decoration: BoxDecoration(
            color: selected
                ? context.colors.background
                : context.colors.background.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: selected ? 0.35 : 0),
                blurRadius: selected ? 14 : 0,
                offset: Offset(0, selected ? 4 : 0),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
