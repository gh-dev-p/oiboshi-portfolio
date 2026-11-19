import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/post_view_totals.dart';
import '../../../domain/models/reach_overview.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/state_view.dart';
import '../../core/ui/viewer_aware_header.dart';
import '../view_models/reach_viewmodel.dart';

/// 届いた数（画面定義書（設定・発信者）2.3.16、届ける・広める仕様書 4.2.2）。発信者メニューから開く。
/// 直近30日の合計と、投稿が見られた数（4.2.3）の合計と、配信・予定ごとの数を出す。数は丸めない。誰かは出さない。
/// 見た目は、本人の指示で Figma を飛ばし、今の画面の部品にそろえた仮の決め（2026-11-16）。
class ReachScreen extends ConsumerWidget {
  const ReachScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(reachOverviewProvider(creatorId));
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.reachTitle),
      body: state.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonBox(height: 240, radius: 20),
        ),
        error: (_, _) => StateView.error(
          onRetry: () => ref.invalidate(reachOverviewProvider(creatorId)),
        ),
        data: (o) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(postViewTotalsProvider(creatorId));
            return ref.refresh(reachOverviewProvider(creatorId).future);
          },
          child: _ReachBody(
            overview: o,
            posts: ref.watch(postViewTotalsProvider(creatorId)).value,
          ),
        ),
      ),
    );
  }
}

class _ReachBody extends StatelessWidget {
  const _ReachBody({required this.overview, required this.posts});

  final ReachOverview overview;

  /// 投稿が見られた数。読めるまでと読めないときは null（「—」を出す）。
  final PostViewTotals? posts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final o = overview;
    final change = o.followed - o.unfollowed;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        SectionLabel(
          l10n.reachLast30Days(monthDay(o.fromDay), monthDay(o.toDay)),
        ),
        SurfacePanel(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _StatRow(label: l10n.reachDelivered, value: o.delivered),
              _StatRow(label: l10n.reachOpened, value: o.opened),
              _StatRow(label: l10n.reachViewed, value: o.viewed),
              _StatRow(
                label: l10n.reachFollowers,
                value: o.followers,
                note: l10n.reachFollowChange(
                  change >= 0 ? '+$change' : '$change',
                  o.followed,
                  o.unfollowed,
                ),
                last: true,
              ),
            ],
          ),
        ),
        SectionLabel(l10n.reachPosts),
        SurfacePanel(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              _StatRow(label: l10n.reachPostShown, value: posts?.shown),
              _StatRow(
                label: l10n.reachPostOpened,
                value: posts?.opened,
                last: true,
              ),
            ],
          ),
        ),
        SectionLabel(l10n.reachBySubject),
        if (o.subjects.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.reachBySubjectEmpty,
              style: TextStyle(fontSize: 14, color: c.textSecondary),
            ),
          )
        else
          SurfacePanel(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < o.subjects.length; i++)
                  _SubjectRow(
                    subject: o.subjects[i],
                    last: i == o.subjects.length - 1,
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            l10n.reachNote,
            style: TextStyle(
              fontSize: 12,
              height: 18 / 12,
              color: c.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 合計の1行（左に名前、右に数）。
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.note,
    this.last = false,
  });

  final String label;

  /// 数。null なら「—」（まだ数えていない）。
  final int? value;
  final String? note;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final v = value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneLineText(
                  label,
                  style: TextStyle(fontSize: 15, color: c.textPrimary),
                ),
                if (note != null)
                  OneLineText(
                    note!,
                    style: TextStyle(fontSize: 12, color: c.textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            v == null ? '—' : withCommas(v),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 配信・予定の1行（左にサービスの印・タイトル・日時、右に数）。
class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject, required this.last});

  final ReachSubject subject;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final s = subject;
    final title = s.title.isNotEmpty
        ? s.title
        : (s.isLive ? l10n.commonLive : l10n.reachDeletedSchedule);
    final at = s.startsAt;
    final kind = s.isLive ? l10n.reachKindLive : l10n.reachKindSchedule;
    final counts = [
      l10n.reachCountDelivered(s.delivered),
      l10n.reachCountOpened(s.opened),
      if (!s.isLive) l10n.reachCountViewed(s.viewed),
    ].join(l10n.commonListSeparator);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox.square(
              dimension: 18,
              child: s.service != null
                  ? PlatformIcon(s.service, size: 18)
                  : Icon(Icons.event, size: 18, color: c.upcomingIcon),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneLineText(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                OneLineText(
                  at == null
                      ? kind
                      : s.allDay
                      ? '$kind・${monthDayWeekday(at.toLocal(), l10n)}'
                      : '$kind・${monthDayWeekday(at.toLocal(), l10n)} '
                            '${clockTime(at.toLocal())}',
                  style: TextStyle(fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  counts,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
