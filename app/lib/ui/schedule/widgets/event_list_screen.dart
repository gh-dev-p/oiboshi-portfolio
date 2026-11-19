import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/event_panel.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../home/widgets/home_tabs.dart';
import '../view_models/event_list_viewmodel.dart';
import '../view_models/schedule_providers.dart';
import 'event_detail_screen.dart';
import '../../core/ui/viewer_aware_header.dart';

/// イベント一覧（画面定義書（スケジュール）2.3.1）。1人のイベントと、推し全員のイベントの両方に使う。
/// これからのイベントを、月の見出しで区切って日付順に並べる。
class EventListScreen extends ConsumerWidget {
  const EventListScreen({
    super.key,
    required this.creators,
    this.openCreator = true,
  });

  final List<Creator> creators;

  /// イベントの詳細で、発信者ページを開けるか（発信者ページから開いたときは開けない）。
  final bool openCreator;

  /// [tab] のタブで開く。ホームからはホームのタブ（戻るとホームに戻る）、発信者ページからは推しのタブ（画面定義書 5.1.8）。
  static Future<void> open(
    BuildContext context, {
    required List<Creator> creators,
    required HomeTab tab,
    bool openCreator = true,
  }) => HomeTabs.open(
    context,
    tab,
    MaterialPageRoute<void>(
      builder: (_) =>
          EventListScreen(creators: creators, openCreator: openCreator),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = EventsKey([for (final c in creators) c.id]);
    final vm = ref.read(eventListViewModelProvider(key).notifier);
    final events = ref.watch(eventListViewModelProvider(key));
    ref.listen(eventListViewModelProvider(key), (prev, next) {
      // 前の値を出したまま読み直しに失敗したら、スナックバーで知らせる（画面定義書 5.1）。
      if (isRefreshFailure(prev, next)) {
        showRefreshFailedSnackBar(context, vm.refresh);
      }
    });
    final byId = {for (final c in creators) c.id: c};
    final single = creators.length == 1 ? creators.first : null;
    return HeaderScaffold(
      appBar: ScreenAppBar(
        title: single == null
            ? l10n.eventListAllTitle
            : l10n.eventListCreatorTitle(single.name),
      ),
      body: asyncBody(
        events,
        loading: () => const _EventListSkeleton(),
        error: () => StateView.error(onRetry: vm.refresh),
        data: (items) => RefreshIndicator(
          onRefresh: vm.refresh,
          child: items.isEmpty
              ? LayoutBuilder(
                  // 空のときも、引き下げで読み直せるように、画面の高さぶんスクロールできるようにする。
                  builder: (context, box) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: box.maxHeight,
                      child: StateView(
                        icon: Icons.event_outlined,
                        title: l10n.commonEventsEmpty,
                        message: l10n.eventListEmptyMessage,
                      ),
                    ),
                  ),
                )
              : _EventList(
                  items: items,
                  byId: byId,
                  showCreator: single == null,
                  openCreator: openCreator,
                ),
        ),
      ),
    );
  }
}

/// 月の見出しと、イベントの行を並べる。
class _EventList extends StatelessWidget {
  const _EventList({
    required this.items,
    required this.byId,
    required this.showCreator,
    required this.openCreator,
  });

  final List<ScheduleItem> items;
  final Map<String, Creator> byId;
  final bool showCreator;
  final bool openCreator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final children = <Widget>[];
    DateTime? month;
    for (final item in items) {
      final start = item.startsAt.toLocal();
      if (month == null ||
          month.year != start.year ||
          month.month != start.month) {
        month = DateTime(start.year, start.month);
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
            child: Text(
              yearMonth(month, l10n),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
        );
      }
      final creator = byId[item.creatorId];
      children.add(
        EventRow(
          item: item,
          creator: creator,
          showCreator: showCreator,
          onTap: creator == null
              ? null
              : () => EventDetailScreen.open(
                  context,
                  item: item,
                  creator: creator,
                  openCreator: openCreator,
                ),
        ),
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      children: children,
    );
  }
}

/// 読み込み中のスケルトン。月の見出しと、日付のブロックつきの行。
class _EventListSkeleton extends StatelessWidget {
  const _EventListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      children: [
        const SkeletonLine(width: 96, height: 14),
        const SizedBox(height: 14),
        for (var i = 0; i < 5; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SkeletonBox(width: 52, height: 56, radius: 10),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 160, height: 14),
                      SizedBox(height: 8),
                      SkeletonLine(width: 110, height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
