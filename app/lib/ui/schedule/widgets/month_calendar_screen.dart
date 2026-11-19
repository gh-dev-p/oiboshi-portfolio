import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../home/widgets/home_tabs.dart';
import '../view_models/month_calendar_viewmodel.dart';
import 'schedule_filter_sheet.dart';
import '../../../domain/models/schedule_filter.dart';
import 'month_day_panel.dart';
import 'month_grid.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 月のカレンダー（画面定義書 2.2.1）。1人の予定と、推し全員の予定の両方に使う。
class MonthCalendarScreen extends ConsumerWidget {
  const MonthCalendarScreen({
    super.key,
    required this.creators,
    required this.initialDay,
    this.openCreator = true,
    this.filterable = false,
  });

  final List<Creator> creators;
  final DateTime initialDay;

  /// 絞り込みを出すか（みんなのカレンダー。画面定義書 2.2.1）。
  final bool filterable;

  /// 予定の詳細に「発信者のページを開く」を出すか（発信者ページから開いたときは出さない。画面定義書 2.1.5）。
  final bool openCreator;

  /// [tab] のタブで開く。ホーム・タイムスケジュールからはスケジュールのタブ、発信者ページからは推しのタブ
  /// （画面定義書 5.1.8）。
  static Future<void> open(
    BuildContext context, {
    required List<Creator> creators,
    DateTime? initialDay,
    bool openCreator = true,
    bool filterable = false,
    HomeTab tab = HomeTab.schedule,
  }) => HomeTabs.open(
    context,
    tab,
    MaterialPageRoute<void>(
      builder: (_) => MonthCalendarScreen(
        creators: creators,
        initialDay: initialDay ?? DateTime.now(),
        openCreator: openCreator,
        filterable: filterable,
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final key = MonthCalendarKey(
      creatorIds: [for (final cr in creators) cr.id],
      initialDay: initialDay,
    );
    final vm = ref.read(monthCalendarViewModelProvider(key).notifier);
    final state = ref.watch(monthCalendarViewModelProvider(key));
    ref.listen(monthCalendarViewModelProvider(key).select((s) => s.data), (
      prev,
      next,
    ) {
      // 前の値を出したまま読み直しに失敗したら、スナックバーで知らせる（画面定義書 5.1）。
      if (isRefreshFailure(prev, next)) {
        showRefreshFailedSnackBar(context, vm.retry);
      }
    });
    final single = creators.length == 1 ? creators.first : null;
    final showFilter = filterable && single == null;
    final filter = showFilter ? state.filter : const ScheduleFilter();
    return HeaderScaffold(
      appBar: ScreenAppBar(
        title: single == null
            ? l10n.scheduleCalendarAllTitle
            : l10n.scheduleCalendarCreatorTitle(single.name),
        actions: [
          if (showFilter)
            HeaderIconButton(
              icon: Icons.filter_list,
              tooltip: l10n.scheduleFilterTitle,
              // 絞り込みが効いている間は、オンの見た目にする。
              selected: filter.isNarrowed([for (final c in creators) c.id]),
              onPressed: () async {
                if (!state.data.hasValue) return;
                final result = await showScheduleFilterSheet(
                  context,
                  creators: creators,
                  current: filter,
                );
                if (result != null) {
                  vm.setFilter(result);
                }
              },
            ),
        ],
      ),
      body: asyncBody(
        state.data,
        loading: () => const _CalendarSkeleton(),
        error: () => StateView.error(onRetry: vm.retry),
        data: (all) {
          final month = all.filtered(filter, [
            for (final cr in creators) cr.id,
          ]);
          return ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 8,
            ),
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    Text(
                      yearMonth(state.month, l10n),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    HeaderIconButton(
                      icon: Icons.chevron_left,
                      tooltip: l10n.schedulePreviousMonth,
                      onPressed: () => vm.moveMonth(-1),
                    ),
                    HeaderIconButton(
                      icon: Icons.chevron_right,
                      tooltip: l10n.scheduleNextMonth,
                      onPressed: () => vm.moveMonth(1),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
              MonthGrid(
                month: state.month,
                selected: state.selected,
                data: month,
                onSelect: vm.selectDay,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: MonthDayPanel(
                  day: state.selected,
                  schedules: month.schedulesOn(state.selected),
                  posts: month.postsOn(state.selected),
                  creators: creators,
                  openCreator: openCreator,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarSkeleton extends StatelessWidget {
  const _CalendarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 120, height: 18),
          const SizedBox(height: 24),
          for (var r = 0; r < 5; r++) ...[
            Row(
              children: [
                for (var i = 0; i < 7; i++)
                  const Expanded(
                    child: Center(
                      child: SkeletonBox(width: 30, height: 30, circle: true),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          const SkeletonBox(height: 120, radius: 20),
        ],
      ),
    );
  }
}
