import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/oshi.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/post_cards.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/state_view.dart';
import '../../core/view_models/playback_provider.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../oshi/widgets/find_creators_screen.dart';
import '../../post/widgets/post_viewer_screen.dart';
import '../../core/ui/panel_header.dart';
import '../../schedule/widgets/event_detail_screen.dart';
import '../../schedule/widgets/event_list_screen.dart';
import '../../core/ui/event_panel.dart';
import '../view_models/home_providers.dart';
import 'home_tabs.dart';
import 'home_live_panel.dart';
import '../view_models/home_viewmodel.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/one_line_text.dart';
import '../../post/widgets/post_impression.dart';

/// ホーム（画面定義書 2.2.1〜2.2.5）。推しの行、次の予定、イベント、全体タイムライン。
class HomeBody extends ConsumerStatefulWidget {
  const HomeBody({super.key});

  @override
  ConsumerState<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<HomeBody> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final vm = ref.read(homeViewModelProvider.notifier);
    // 下部ナビのホームを、ホームを開いているときに押したら、いちばん上まで戻す。
    ref.listen(homeScrollToTopProvider, (_, _) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
    // 表示済みの内容があるときの更新の失敗は、内容を残したままスナックバーで知らせる。
    ref.listen(homeViewModelProvider, (prev, next) {
      if (isRefreshFailure(prev, next)) {
        showRefreshFailedSnackBar(context, vm.refresh);
      }
    });
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(homeViewModelProvider);
    // 固定ビューアを出している間は、ヘッダーを出さない（固定ビューアが上に据わるので、縦を空ける。画面定義書 5.1.2）。
    final midMini = ref.watch(playbackProvider) != null;
    final header = TabHeader(
      title: l10n.appTitle,
      titleWidget: const _HomeLogo(),
      centered: true,
      // ヘッダーの高さは、ロゴに替える前（文字の「追星」）と同じ 48。スケジュールのタブとそろう。
      height: 48,
    );
    final body = asyncBody(
      state,
      data: (data) => data.oshis.isEmpty
          ? StateView(
              icon: Icons.star_border,
              title: l10n.homeEmptyTitle,
              message: l10n.homeEmptyMessage,
              buttonLabel: l10n.commonFindCreatorsTitle,
              onPressed: () => FindCreatorsScreen.open(context),
            )
          : _HomeContent(
              state: data,
              controller: _scroll,
              onLoadMore: vm.loadMore,
              onRetryLoadMore: vm.retryLoadMore,
              onRefresh: vm.refresh,
            ),
      loading: () => const _HomeSkeleton(),
      error: () => StateView.error(onRetry: vm.refresh),
    );
    // iOS のステータスバーを押したときも、同じ位置から上に戻す。
    return PrimaryScrollController(
      controller: _scroll,
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (!midMini) header,
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// ホームのヘッダーのロゴ（画面定義書（ファン向け）2.2.1）。暗い画面では、線と文字を白にした絵を出す。
class _HomeLogo extends StatelessWidget {
  const _HomeLogo();

  /// ロゴの高さ。画面が詰まっているので、小さめにする（2026-11-09 本人）。
  static const double height = 28;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      dark ? 'assets/logo/home_logo_dark.png' : 'assets/logo/home_logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({
    required this.state,
    required this.controller,
    required this.onLoadMore,
    required this.onRetryLoadMore,
    required this.onRefresh,
  });

  final HomeState state;
  final ScrollController controller;
  final VoidCallback onLoadMore;

  /// 続きを読めなかったときの「再試行」。
  final VoidCallback onRetryLoadMore;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final byId = {for (final o in state.oshis) o.id: o.creator};
    final bottom = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // 縦方向・いちばん外側のスクロールだけで、続きを読む（推しの行の横スクロールでは読まない）。
          if (n.depth == 0 &&
              n.metrics.axis == Axis.vertical &&
              n.metrics.extentAfter < 800) {
            onLoadMore();
          }
          return false;
        },
        child: CustomScrollView(
          controller: controller,
          // 画面の少し先の投稿まで組み立てて、画像を見える前から読み込む。
          scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
          slivers: [
            SliverToBoxAdapter(
              child: _OshiStrip(oshis: state.oshis, now: now),
            ),
            HomeLivePanel(
              oshis: state.oshis,
              now: now,
              scrollController: controller,
              top: _OshiStrip.heightOf(context),
            ),
            SliverToBoxAdapter(
              child: _UpcomingPanel(
                items: state.upcoming,
                byId: byId,
                now: now,
                more: state.upcomingMore,
                // 「ほか N 件」：スケジュールのタブ（24時間のタイムスケジュール）へ移る。
                // タブの中で別の画面（月のカレンダーなど）を開いていたら、閉じてから出す。
                onMore: () => HomeTabs.showRoot(context, HomeTab.schedule),
              ),
            ),
            SliverToBoxAdapter(
              child: EventPanel(
                items: state.events,
                creatorOf: (item) => byId[item.creatorId],
                more: state.eventsMore,
                // 「ほか N 件」：推し全員のイベント一覧を、ホームのタブの中で開く（戻るとホームに戻る）。
                onMore: () => EventListScreen.open(
                  context,
                  creators: [for (final o in state.oshis) o.creator],
                  tab: HomeTab.home,
                ),
                onTap: (item, creator) => EventDetailScreen.open(
                  context,
                  item: item,
                  creator: creator,
                ),
              ),
            ),
            SliverList.separated(
              itemCount: state.posts.length,
              // 投稿の間は線を引かず、余白で区切る。
              separatorBuilder: (_, i) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final post = state.posts[i];
                final author = byId[post.creatorId];
                if (author == null) return const SizedBox.shrink();
                return PostImpression(
                  post: post,
                  child: PostCard(
                    post: post,
                    author: author,
                    now: now,
                    onTap: () => PostViewerScreen.open(
                      context,
                      posts: state.posts,
                      initialIndex: i,
                      authorOf: (p) => byId[p.creatorId],
                      onOpenAuthor: (author) =>
                          CreatorScreen.open(context, author.id),
                    ),
                    onAuthorTap: () => CreatorScreen.open(context, author.id),
                  ),
                );
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottom),
                child: Center(
                  child: state.exhausted
                      ? Text(
                          state.posts.isEmpty
                              ? l10n.commonNoPostsYet
                              : l10n.homeTimelineEnd,
                          style: context.textStyles.hint,
                        )
                      // 続きを読めなかったら、印を止めて、「読み込めませんでした」と「再試行」を出す。
                      : state.loadMoreFailed
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.commonLoadFailedTitle,
                              style: context.textStyles.hint,
                            ),
                            TextButton(
                              onPressed: onRetryLoadMore,
                              child: Text(l10n.commonRetry),
                            ),
                          ],
                        )
                      // 続きを読んでいるあいだだけ、読み込み中の印を出す。
                      : SizedBox(
                          width: 20,
                          height: 20,
                          child: state.loadingMore
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              : null,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 推しレーン。丸いアイコンを横に並べ、横にスクロールする（画面定義書（ファン）2.2.1）。
/// 赤いリングは、配信ビューアで流している推しだけに付け、ほかの配信中の推しは「LIVE」、新着ありは「NEW」の印を出す。
class _OshiStrip extends ConsumerWidget {
  const _OshiStrip({required this.oshis, required this.now});

  final List<Oshi> oshis;
  final DateTime now;

  /// 高さ。上下の余白（8・12）、アイコン（72）、間（6）、名前の1行（16）。名前は、文字の大きさの設定に合わせて伸ばす。
  /// 固定ビューアを出している間も、上の余白を取る（余白はレーンの側に入れ、固定ビューアとの間には空けない）。
  static double heightOf(BuildContext context) =>
      8 + 72 + 6 + MediaQuery.textScalerOf(context).scale(16) + 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final playing = playingLiveCreatorId(
      oshis,
      now,
      ref.watch(playbackProvider),
      ref.watch(homeLiveViewerProvider),
    );
    return SizedBox(
      height: heightOf(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        itemCount: oshis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final oshi = oshis[i];
          final live = oshi.creator.liveAt(now);
          final status = oshi.ringAt(now);
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            // 配信中で、配信ビューアで流していない推しは、配信ビューアをその推しに切り替える。
            onTap: live != null && oshi.id != playing
                ? () =>
                      ref.read(homeLiveViewerProvider.notifier).show(oshi, live)
                : () => CreatorScreen.open(context, oshi.id),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  OshiAvatar(
                    avatarUrl: oshi.creator.avatarUrl,
                    size: 72,
                    ring: oshi.id == playing ? OshiRing.live : OshiRing.read,
                    badge: OshiBadge.fromRing(status),
                  ),
                  const SizedBox(height: 6),
                  OneLineText(
                    oshi.creator.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 「次の予定」。角丸の面に、次の予定（本日中）、つまり今日のこれからの予定を時刻順に縦に並べる。
class _UpcomingPanel extends StatelessWidget {
  const _UpcomingPanel({
    required this.items,
    required this.byId,
    required this.now,
    required this.more,
    required this.onMore,
  });

  final List<ScheduleItem> items;
  final Map<String, Creator> byId;
  final DateTime now;

  /// 出しきれない件数。1件以上なら、見出しの右に「ほか N 件」を出す。
  final int more;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListPanel(
      title: l10n.homeUpcomingTitle,
      more: more,
      onMore: onMore,
      emptyText: l10n.homeUpcomingEmpty,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      children: [
        for (var i = 0; i < items.length; i++)
          _UpcomingRow(
            item: items[i],
            creator: byId[items[i].creatorId],
            last: i == items.length - 1,
          ),
      ],
    );
  }
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.creator,
    required this.last,
  });

  final ScheduleItem item;
  final Creator? creator;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final creator = this.creator;
    return InkWell(
      onTap: creator == null
          ? null
          : () => CreatorScreen.open(context, creator.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: last ? null : Border(bottom: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            // 推しが配信中でも、予定の開始時刻を出す（これからの予定だけを並べるため）。本日中の予定だけなので、日付は出さない。
            // 数字の幅をそろえ、入りきらないとき（文字を大きくする設定など）は、折り返さずに縮める。
            SizedBox(
              width: 48,
              height: 20,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  clockTime(item.startsAt),
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
            const SizedBox(width: 12),
            AvatarImage(url: creator?.avatarUrl, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineText(
                    l10n.scheduleTitle(item),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  OneLineText(
                    creator?.name ?? '',
                    style: context.textStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PlatformIcon(item.service, size: 20),
          ],
        ),
      ),
    );
  }
}

/// ホーム（読み込み中）のスケルトン。
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 推しの行は、画面の幅を超えて右に続く（実際の行と同じく、横に並べたまま切る）。
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  const SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        SkeletonBox(width: 72, height: 72, circle: true),
                        SizedBox(height: 8),
                        SkeletonLine(width: 48, height: 10),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 「次の予定」（2行）と「イベント」（2行）。
          for (final (top, rows) in [(4.0, 2), (0.0, 2)])
            Padding(
              padding: EdgeInsets.fromLTRB(12, top, 12, 12),
              child: SurfacePanel(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLine(width: 72),
                    for (var i = 0; i < rows; i++) ...[
                      const SizedBox(height: 14),
                      const Row(
                        children: [
                          SkeletonLine(width: 36),
                          SizedBox(width: 12),
                          SkeletonBox(width: 36, height: 36, circle: true),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLine(width: 150),
                              SizedBox(height: 6),
                              SkeletonLine(width: 80, height: 10),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          for (final withImage in [true, false])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 40, height: 40, circle: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonLine(width: 140),
                        const SizedBox(height: 8),
                        const SkeletonLine(),
                        const SizedBox(height: 8),
                        const SkeletonLine(width: 220),
                        if (withImage) ...[
                          const SizedBox(height: 8),
                          const SkeletonBox(height: 110, radius: 12),
                        ],
                      ],
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
