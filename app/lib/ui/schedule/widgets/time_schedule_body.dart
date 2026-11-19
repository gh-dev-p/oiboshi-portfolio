import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/oshi.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/view_models/playback_provider.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/glass_surface.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../view_models/time_schedule_viewmodel.dart';
import 'month_calendar_screen.dart';
import 'schedule_filter_sheet.dart';
import 'schedule_table.dart';
import 'week_strip.dart';

/// タイムスケジュール（画面定義書 2.1.1・2.1.2）。縦軸が時間、列が推しごとの表。
class TimeScheduleBody extends ConsumerStatefulWidget {
  const TimeScheduleBody({super.key});

  @override
  ConsumerState<TimeScheduleBody> createState() => _TimeScheduleBodyState();
}

class _TimeScheduleBodyState extends ConsumerState<TimeScheduleBody> {
  /// 週ストリップの今日をもう一度押すたびに増やし、表を現在時刻へ移す。
  final _scrollToNow = ValueNotifier<int>(0);

  /// 下部ナビのスケジュールをもう一度押すたびに増やし、表の真ん中へ現在時刻を移す。
  final _centerNow = ValueNotifier<int>(0);

  /// 下部ナビのスケジュールをもう一度押して、今日に戻している途中（今日の表が出たら、真ん中へ移す）。
  bool _centerNowPending = false;

  @override
  void dispose() {
    _scrollToNow.dispose();
    _centerNow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(timeScheduleViewModelProvider.notifier);
    final state = ref.watch(timeScheduleViewModelProvider);
    ref.listen(timeScheduleViewModelProvider.select((s) => s.result), (
      prev,
      next,
    ) {
      // 前の値を出したまま読み直しに失敗したら、スナックバーで知らせる。
      // 日を切り替えた失敗は [next] に値がないので、表示中のデータで見る。
      final hasContent = ref.read(timeScheduleViewModelProvider).data != null;
      if (isRefreshFailure(prev, next, hasContent: hasContent)) {
        showRefreshFailedSnackBar(context, vm.refresh);
      }
    });
    // 下部ナビのスケジュールをもう一度押したら、今日に戻してから、今の時刻を真ん中へ移す。
    ref.listen(scheduleScrollToNowProvider, (_, _) {
      _centerNowPending = true;
      final today = vm.today;
      if (!isSameDay(ref.read(timeScheduleViewModelProvider).day, today)) {
        vm.selectDay(today);
      }
      setState(() {});
    });
    final data = state.data;
    // 読み込み中も、推しがいないものとして扱う（読めるまで、絞り込みとカレンダーへは押せない）。
    final oshis = data?.allOshis ?? const <Oshi>[];
    final weekStart = state.weekStart;
    final now = DateTime.now();
    // 固定ビューアを出している間は、年月の帯を出さず、3つのボタンを表の右下に浮かせる（画面定義書（スケジュール）2.1.1）。
    final viewerShown = ref.watch(fixedViewerShownProvider);
    final actions = <_ScheduleAction>[
      (
        icon: state.filter.hideEmpty
            ? Icons.visibility_off
            : Icons.visibility_off_outlined,
        tooltip: l10n.scheduleFilterHideEmpty,
        selected: state.filter.hideEmpty,
        // 切り替えたら、何が変わったか分かるように知らせる。
        onPressed: () {
          final hide = !state.filter.hideEmpty;
          vm.setFilter(state.filter.copyWith(hideEmpty: hide));
          showAppSnackBar(
            context,
            hide ? l10n.scheduleHideEmptyOn : l10n.scheduleHideEmptyOff,
          );
        },
      ),
      (
        icon: Icons.filter_list,
        tooltip: l10n.scheduleFilterTitle,
        // 絞り込みが効いている間は、オンの見た目にする。
        selected: state.filter.isNarrowed([
          for (final o in oshis) o.creator.id,
        ]),
        // 推しがいないときは、押せない（画面定義書（スケジュール）2.1.6）。
        onPressed: oshis.isEmpty
            ? null
            : () async {
                final result = await showScheduleFilterSheet(
                  context,
                  creators: [for (final o in oshis) o.creator],
                  current: state.filter,
                );
                if (result != null) vm.setFilter(result);
              },
      ),
      (
        icon: Icons.calendar_month,
        tooltip: l10n.scheduleOpenCalendar,
        selected: null,
        // 絞り込みは引き継がず、推し全員で開く（みんなのカレンダーの絞り込みで出す）。
        // 推しがいないときは、押せない（画面定義書（スケジュール）2.1.6）。
        onPressed: oshis.isEmpty
            ? null
            : () => MonthCalendarScreen.open(
                context,
                creators: [for (final o in oshis) o.creator],
                initialDay: state.day,
                filterable: true,
              ),
      ),
    ];
    final floating = viewerShown ? _FloatingActions(actions) : null;
    final Widget body;
    if (data != null) {
      final d = data;
      body = d.allOshis.isEmpty
          ? StateView(
              icon: Icons.event,
              title: l10n.scheduleEmptyTitle,
              message: l10n.scheduleEmptyMessage,
            )
          : ScheduleTable(
              data: d,
              filter: state.filter,
              now: now,
              scrollToNow: _scrollToNow,
              centerNow: _centerNow,
              floating: floating,
              fitToScreenBottom: viewerShown,
            );
      // 今日の表が出たら、真ん中へ移す（今日に戻している途中なら、読めるのを待つ）。
      if (_centerNowPending && isSameDay(d.day, vm.today)) {
        _centerNowPending = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerNow.value++);
      }
    } else if (state.result.hasError && !state.result.isLoading) {
      body = StateView.error(onRetry: vm.refresh);
    } else {
      body = const _ScheduleSkeleton();
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!viewerShown)
              TabHeader(
                title: yearMonth(state.day, l10n),
                titleSize: 20,
                height: 48,
                actions: [
                  for (final a in actions)
                    HeaderIconButton(
                      icon: a.icon,
                      tooltip: a.tooltip,
                      selected: a.selected,
                      onPressed: a.onPressed,
                    ),
                ],
              ),
            WeekStrip(
              weekStart: weekStart,
              selected: state.day,
              today: now,
              onSelect: vm.selectDay,
              onTodayReselected: () => _scrollToNow.value++,
              // 固定ビューアを出している間は、曜日と日付を1段にまとめ、その分だけ表を上に広げる。
              compact: viewerShown,
            ),
            Expanded(
              child: Padding(
                // 下部ナビのぶんだけ、下に余白を取る。表は、詳細のパネルを下部ナビの後ろまで伸ばすので、自分で取る。
                padding: EdgeInsets.only(
                  bottom: body is ScheduleTable
                      ? 0
                      : MediaQuery.paddingOf(context).bottom,
                ),
                child: floating == null || body is ScheduleTable
                    ? body
                    : Stack(
                        children: [
                          Positioned.fill(child: body),
                          Positioned(
                            right: _FloatingActions.margin,
                            bottom: _FloatingActions.margin,
                            child: floating,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 年月の帯の右の、1つのボタン。帯に置くときと、浮かせるときで同じものを使う。
typedef _ScheduleAction = ({
  IconData icon,
  String tooltip,
  bool? selected,
  VoidCallback? onPressed,
});

/// 固定ビューアを出している間に、表の右下に縦に並べて浮かせるボタン（すりガラスの丸）。
/// 押したときの動き・押せないとき・オンの見え方は、帯のボタン（[HeaderIconButton]）と同じ。
class _FloatingActions extends StatelessWidget {
  const _FloatingActions(this.actions);

  final List<_ScheduleAction> actions;

  /// 表の右と下からの間。
  static const margin = 12.0;
  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          GlassSurface(
            width: _size,
            height: _size,
            child: HeaderIconButton(
              icon: a.icon,
              tooltip: a.tooltip,
              selected: a.selected,
              onPressed: a.onPressed,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleSkeleton extends StatelessWidget {
  const _ScheduleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                const Expanded(
                  child: Column(
                    children: [
                      SkeletonBox(width: 30, height: 30, circle: true),
                      SizedBox(height: 4),
                      SkeletonLine(width: 36, height: 8),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 8; i++) ...[
            const SkeletonLine(height: 1),
            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}
