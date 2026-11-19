import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../domain/models/oshi.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/follow_button.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/post_cards.dart';
import '../../core/ui/sns_style.dart';
import '../../post/widgets/post_viewer_screen.dart';
import '../../../config/app_constants.dart';
import '../../home/widgets/home_tabs.dart';
import '../../schedule/widgets/event_detail_screen.dart';
import '../../schedule/widgets/event_list_screen.dart';
import '../../core/ui/event_panel.dart';
import '../../schedule/widgets/schedule_detail_sheet.dart';
import '../view_models/creator_viewmodel.dart';
import 'creator_link_buttons.dart';
import 'creator_cover.dart';
import 'creator_page_parts.dart';
import '../../core/ui/one_line_text.dart';
import '../../post/widgets/post_impression.dart';

/// 発信者ページ（画面定義書 2.4.1）。
/// カバー、アイコン、名前の行、ID、プロフィール文、フォロワー数、次の予定、イベント、投稿。
/// 配信中も同じ見た目にし、アイコンに「LIVE」の印を付ける（配信スクリーンモードはやめた。2026-11-19 本人）。
class CreatorProfilePage extends StatelessWidget {
  const CreatorProfilePage({
    super.key,
    required this.state,
    required this.now,
    required this.vm,
    this.live = false,
    this.onWatchLive,
  });

  final CreatorPageState state;
  final DateTime now;
  final CreatorViewModel vm;

  /// 配信中か。アイコンを、赤いリングと「LIVE」の印にする（ホームの推しの丸と同じ）。
  final bool live;

  /// 「固定ビューアで見る」を押したとき（配信中で、固定ビューアでその配信を流していないときだけ）。null なら出さない。
  final VoidCallback? onWatchLive;

  /// カメラのアイコン。「写真を選ぶ」と、自分の写真があるときは「推しが設定したカバーに戻す」を出す。
  Future<void> _changeCover(BuildContext context) async {
    final action = await showCoverMenu(context, hasOwnCover: state.hasOwnCover);
    if (action == null) return;
    final result = switch (action) {
      CoverMenuAction.pick => await vm.pickAndSetCover(),
      CoverMenuAction.reset => await vm.resetCover(),
    };
    if (result == CoverChangeResult.failed && context.mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.creatorCoverChangeFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final creator = state.creator;
    final dividerIndex = state.newDividerIndexAt(now);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;
    // 名前・@ID・プロフィール文の大きさは、YouTube の iOS アプリのチャンネルのページに合わせる（2026-11-19 本人）。
    final name = Text(
      creator.name,
      style: TextStyle(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
      ),
    );
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: CustomScrollView(
        // 画面の少し先の投稿まで組み立てて、画像を見える前から読み込む。
        scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              creatorCoverUrl: creator.coverUrl,
              ownCoverUrl: state.ownCoverUrl,
              showingOwnCover: state.showingOwnCover,
              onFlipCover: vm.flipCover,
              avatarUrl: creator.avatarUrl,
              live: live,
              topInset: topInset,
              onChangeCover: state.following
                  ? () => _changeCover(context)
                  : null,
              menu: CreatorMenuButton(
                creator: creator,
                vm: vm,
                ownPage: !state.showMenu,
                color: c.textPrimary.withValues(alpha: 0.45),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: name),
                      const SizedBox(width: 8),
                      // フォロー中は、ベルだけの丸いボタン（押すと、通知の切り替えとフォローをやめるのシート）。
                      if (state.following)
                        CreatorBellButton(notify: state.follow!.notify, vm: vm)
                      else
                        FollowButton(
                          following: false,
                          withCheck: true,
                          onPressed: () async {
                            if (!await vm.toggleFollow() && context.mounted) {
                              showAppSnackBar(
                                context,
                                l10n.commonFollowChangeFailed,
                              );
                            }
                          },
                        ),
                      const SizedBox(width: 8),
                      CreatorCalendarButton(
                        creator: creator,
                        hasUpcoming: state.hasUpcoming,
                        size: 36,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    creator.handle,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: c.textMuted,
                    ),
                  ),
                  // 配信中で、固定ビューアでその配信を流していなければ、固定ビューアで流すボタン（2026-11-19 本人）。
                  if (onWatchLive case final watch?) ...[
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: l10n.creatorWatchLive,
                      onPressed: watch,
                    ),
                  ],
                  if (creator.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    CreatorBio(
                      creator.bio,
                      style: TextStyle(
                        fontSize: 14,
                        height: 20 / 14,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                  if (creator.totalFollowers != null) ...[
                    const SizedBox(height: 14),
                    CreatorFollowerCounts(creator: creator),
                  ],
                  // リンク集（届ける・広める仕様書 4.6.2）。合計フォロワー数の下に、ボタンで並べる。なければ何も出さない。
                  CreatorLinkButtons(
                    creatorId: creator.id,
                    canReport: state.showMenu,
                    snsAccounts: creator.accounts,
                    padding: const EdgeInsets.only(top: 12),
                  ),
                ],
              ),
            ),
          ),
          if (state.next != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: _NextScheduleCard(
                  item: state.next!,
                  now: now,
                  onTap: () => showScheduleDetailSheet(
                    context,
                    item: state.next!,
                    creator: creator,
                    openCreator: false,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: EventPanel(
              items: state.events.take(upcomingEventCount).toList(),
              creatorOf: (_) => creator,
              showCreator: false,
              more: state.events.length > upcomingEventCount
                  ? state.events.length - upcomingEventCount
                  : 0,
              // 「ほか N 件」：この発信者のイベント一覧を、発信者ページと同じタブ（ふつうは推しのタブ）の中で開く（画面定義書 5.1.8）。
              onMore: () => EventListScreen.open(
                context,
                creators: [creator],
                openCreator: false,
                tab: HomeTabs.tabOf(context) ?? HomeTab.oshi,
              ),
              onTap: (item, _) => EventDetailScreen.open(
                context,
                item: item,
                creator: creator,
                openCreator: false,
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            ),
          ),
          SliverList.builder(
            itemCount: state.posts.length,
            itemBuilder: (context, i) {
              final post = state.posts[i];
              return Column(
                children: [
                  // 投稿の間は線を引かず、余白で区切る。
                  if (i > 0 && dividerIndex != i - 1)
                    const SizedBox(height: 16),
                  PostImpression(
                    post: post,
                    child: PostCard(
                      post: post,
                      author: creator,
                      now: now,
                      onTap: () => PostViewerScreen.open(
                        context,
                        posts: state.posts,
                        initialIndex: i,
                        authorOf: (_) => creator,
                      ),
                    ),
                  ),
                  if (dividerIndex == i) const _NewPostsDivider(),
                ],
              );
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottom),
              child: state.posts.isEmpty
                  ? Center(
                      child: Text(
                        l10n.commonNoPostsYet,
                        style: context.textStyles.hint,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// カバー画像とアイコン。カバーの下側を背景に溶かし、アイコンをカバーの下中央に置く。
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.creatorCoverUrl,
    required this.ownCoverUrl,
    required this.showingOwnCover,
    required this.onFlipCover,
    required this.avatarUrl,
    required this.live,
    required this.topInset,
    required this.onChangeCover,
    this.menu,
  });

  /// カバーの表（発信者のカバー）と裏（ファンが選んだ自分の写真）。
  final String? creatorCoverUrl;
  final String? ownCoverUrl;
  final bool showingOwnCover;
  final VoidCallback onFlipCover;
  final String? avatarUrl;
  final bool live;
  final double topInset;
  final VoidCallback? onChangeCover;

  /// カバーの右上のメニュー（「…」）。null なら出さない。
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // カバーは横3：縦1。上のステータスバーの分は、その上に足す。
    final imageHeight =
        MediaQuery.sizeOf(context).width / creatorCoverAspectRatio;
    final coverHeight = imageHeight + topInset;
    // 下を背景に溶かすぼかしは、カバーの高さに合わせる（前の 180 のときの 81 と同じ割合）。
    final fadeHeight = imageHeight * 0.45;
    return SizedBox(
      height: coverHeight + 60,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: coverHeight,
            child: CreatorCover(
              frontUrl: creatorCoverUrl,
              backUrl: ownCoverUrl,
              showBack: showingOwnCover,
              onFlip: onFlipCover,
              indicatorTop: topInset + 22,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: coverHeight - fadeHeight,
            height: fadeHeight,
            // カバーを押して裏返せるよう、重ねたぼかしは押せなくする。
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.background.withValues(alpha: 0), c.background],
                  ),
                ),
              ),
            ),
          ),
          if (menu != null)
            Positioned(right: 12, top: topInset + 9, child: menu!),
          if (onChangeCover != null)
            Positioned(
              // メニューがあれば、その左に置く。
              right: menu == null ? 12 : 56,
              top: topInset + 9,
              child: IconButton(
                onPressed: onChangeCover,
                tooltip: AppLocalizations.of(context)!.creatorChangeCover,
                iconSize: 18,
                icon: Icon(
                  Icons.photo_camera,
                  color: c.textPrimary.withValues(alpha: 0.45),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            top: coverHeight - 48,
            child: Center(
              child: live
                  ? OshiAvatar(
                      avatarUrl: avatarUrl,
                      size: 96,
                      ring: OshiRing.live,
                      badge: OshiBadge.live,
                    )
                  : OshiAvatar(
                      avatarUrl: avatarUrl,
                      size: 96,
                      borderColor: c.background,
                      borderWidth: 3,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「次の予定」のカード。見出しに、あとどれくらいかを出す。
class _NextScheduleCard extends StatelessWidget {
  const _NextScheduleCard({
    required this.item,
    required this.now,
    required this.onTap,
  });

  final ScheduleItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final service = item.service;
    final startsAt = item.startsAt;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.creatorNextScheduleHeader(
                        untilLabel(startsAt, now: now, l10n: l10n),
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    OneLineText(
                      l10n.scheduleTitle(item),
                      style: TextStyle(
                        fontSize: 16,
                        height: 24 / 16,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        PlatformIcon(service, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          l10n.creatorNextScheduleMeta(
                            service == null
                                ? l10n.creatorNextScheduleEvent
                                : l10n.sns(service),
                            monthDayWeekday(startsAt, l10n),
                            clockTime(startsAt),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 24, color: c.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPostsDivider extends StatelessWidget {
  const _NewPostsDivider();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: c.primary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              AppLocalizations.of(context)!.creatorNewPostsDivider,
              style: TextStyle(
                fontSize: 11,
                height: 16 / 11,
                fontWeight: FontWeight.w700,
                color: c.primary,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: c.primary)),
        ],
      ),
    );
  }
}
