import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/schedule_item.dart';
import '../../../domain/models/schedule_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/sns_style.dart';
import '../../creator/widgets/creator_screen.dart';
import 'posts_group_card.dart';
import 'schedule_detail_sheet.dart';
import 'schedule_editor.dart';

/// 詳細のパネルで選んでいる、表の要素（画面定義書 2.1.3）。
sealed class ScheduleFocus {
  const ScheduleFocus(this.creator);

  final Creator creator;

  /// 表の上で、どの要素かを見分ける（[ScheduleBlock.key]・[PostCluster.key]）。
  String get key;

  /// パネルに隠れないように合わせる時刻。「終日」の予定は、合わせない。
  DateTime? get time;
}

/// 配信・イベントの公演のブロック。
class BlockFocus extends ScheduleFocus {
  const BlockFocus(this.block, super.creator);

  final ScheduleBlock block;

  @override
  String get key => block.key;

  @override
  DateTime get time => block.start;
}

/// 投稿チップ・「+N」。
class ClusterFocus extends ScheduleFocus {
  const ClusterFocus(this.cluster, super.creator);

  final PostCluster cluster;

  @override
  String get key => cluster.key;

  @override
  DateTime get time => cluster.time;
}

/// 「終日」の予定。
class AllDayFocus extends ScheduleFocus {
  const AllDayFocus(this.item, super.creator);

  final ScheduleItem item;

  /// [item] を選んだときの [key]。「終日」のピルを目立たせるのに使う。
  static String keyOf(ScheduleItem item) => 'schedule:${item.id}';

  @override
  String get key => keyOf(item);

  @override
  DateTime? get time => null;
}

/// 詳細のパネル（画面定義書 2.1.3）。表の下に重ね、背面は暗くしない。
/// 種類を問わず、選んだ要素の中身をカードで出す。開いているあいだは高さを変えず、中身だけを替える
/// （高さが変わると、表の下の余白とスクロールも動き、画面がちらつくため）。
/// 左右のスワイプで、表の上の次・前の要素へ送る。
class ScheduleDetailPanel extends StatefulWidget {
  const ScheduleDetailPanel({
    super.key,
    required this.focus,
    required this.postsOf,
    required this.height,
    required this.bottomPadding,
    required this.onClose,
    this.onStep,
    this.swipeDirection = 0,
  });

  final ScheduleFocus focus;

  /// その推しの投稿すべて（新しい順）。ビューアで前後に移るのに使う。
  final List<Post> Function(Creator creator) postsOf;

  /// パネルの高さ（下の余白を含む）。
  final double height;

  /// 下の余白（下部ナビのぶん）。
  final double bottomPadding;
  final VoidCallback onClose;

  /// 左右のスワイプで呼ぶ。左へ払うと 1（次へ）、右へ払うと -1（前へ）。
  final ValueChanged<int>? onStep;

  /// 直前に送った向き（1：次へ、-1：前へ、0：要素を押して開いた）。新しい中身を、その向きから入れる。
  final int swipeDirection;

  @override
  State<ScheduleDetailPanel> createState() => _ScheduleDetailPanelState();
}

/// 左右に払ったとみなす、指の動きの長さと速さ。
const _swipeDistance = 60.0;
const _swipeVelocity = 300.0;

class _ScheduleDetailPanelState extends State<ScheduleDetailPanel> {
  /// 今の横のドラッグで動いた長さ。
  double _dragDx = 0;

  ScheduleFocus get focus => widget.focus;

  void _onHorizontalDragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    final dx = _dragDx;
    _dragDx = 0;
    // 左へ払う（指が左へ動く）と次へ、右へ払うと前へ。
    if (dx <= -_swipeDistance || velocity <= -_swipeVelocity) {
      widget.onStep?.call(1);
    } else if (dx >= _swipeDistance || velocity >= _swipeVelocity) {
      widget.onStep?.call(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final direction = widget.swipeDirection;
    return GestureDetector(
      // パネルの上を押しても、表の「何もないところ」として閉じないようにする。
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 300) widget.onClose();
      },
      // パネルの中の縦のスクロールとは、向きで分かれる（ジェスチャーの取り合いで、先に動いた向きが取る）。
      onHorizontalDragStart: widget.onStep == null ? null : (_) => _dragDx = 0,
      onHorizontalDragUpdate: widget.onStep == null
          ? null
          : (d) => _dragDx += d.primaryDelta ?? 0,
      onHorizontalDragEnd: widget.onStep == null ? null : _onHorizontalDragEnd,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: c.shadow,
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 32,
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.handle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    bottom: 0,
                    child: IconButton(
                      tooltip: l10n.commonClose,
                      iconSize: 20,
                      icon: Icon(Icons.close, color: c.textSecondary),
                      onPressed: widget.onClose,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRect(
                // スワイプで送ったときは、新しい中身を払った向きから入れる。要素を押したときは、すぐに替える。
                child: AnimatedSwitcher(
                  duration: direction == 0
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  layoutBuilder: (current, previous) =>
                      Stack(children: [...previous, ?current]),
                  transitionBuilder: (child, animation) {
                    final fade = FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                    if (child.key != ValueKey(focus.key)) return fade;
                    return SlideTransition(
                      position: Tween(
                        begin: Offset(0.25 * direction, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: fade,
                    );
                  },
                  // 要素を替えたら、中身のスクロールは上に戻す。
                  child: SingleChildScrollView(
                    key: ValueKey(focus.key),
                    // 中身は下部ナビの後ろまで流し、終わりに下部ナビのぶんの余白を入れて、最後（ボタンなど）がナビに隠れないようにする。
                    padding: EdgeInsets.only(bottom: 8 + widget.bottomPadding),
                    child: _content(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final creator = focus.creator;
    return switch (focus) {
      BlockFocus(:final block) when block.isLiveNow => _LiveCard(
        block: block,
        creator: creator,
      ),
      BlockFocus(:final block) when block.item != null => ScheduleDetailCard(
        item: block.item!,
        creator: creator,
        onOpenCreator: () => CreatorScreen.open(context, creator.id),
        onEdit: () => openScheduleEditor(
          context,
          item: block.item!,
          creatorId: creator.id,
        ),
      ),
      BlockFocus() => const SizedBox.shrink(),
      AllDayFocus(:final item) => ScheduleDetailCard(
        item: item,
        creator: creator,
        onOpenCreator: () => CreatorScreen.open(context, creator.id),
        onEdit: () =>
            openScheduleEditor(context, item: item, creatorId: creator.id),
      ),
      ClusterFocus(:final cluster) => PostsGroupCard(
        creator: creator,
        posts: cluster.posts,
        allPosts: widget.postsOf(creator),
      ),
    };
  }
}

/// 配信中の配信のカード。押すと、発信者ページへ。
class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.block, required this.creator});

  final ScheduleBlock block;
  final Creator creator;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              AvatarImage(url: creator.avatarUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      l10n.scheduleLiveNow,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: c.live,
                      ),
                    ),
                  ],
                ),
              ),
              PlatformIcon(block.service, size: 26),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            block.title.isEmpty ? l10n.commonLive : block.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            label: l10n.scheduleWatchLive,
            onPressed: () => CreatorScreen.open(context, creator.id),
          ),
        ),
      ],
    );
  }
}
