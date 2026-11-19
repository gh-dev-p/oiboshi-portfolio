import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/post_cards.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../post/widgets/post_viewer_screen.dart';
import '../../post/widgets/post_impression.dart';

/// 投稿の一覧のカード（画面定義書 2.1.3）。詳細のパネルで、投稿チップと「+N」の中身を出す。
/// 推しのアイコン、「{推し}の投稿」、時刻と件数、投稿の一覧。
class PostsGroupCard extends StatelessWidget {
  const PostsGroupCard({
    super.key,
    required this.creator,
    required this.posts,
    required this.allPosts,
  });

  final Creator creator;

  /// まとめた投稿（新しい順）。
  final List<Post> posts;

  /// その推しの投稿すべて（新しい順）。ビューアで前後に移るのに使う。
  final List<Post> allPosts;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final hour = posts.last.postedAt.hour;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              AvatarImage(url: creator.avatarUrl, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.schedulePostsGroupTitle(creator.name),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.schedulePostsGroupSubtitle(hour, posts.length),
                      style: context.textStyles.hint,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < posts.length; i++) ...[
          if (i > 0) Divider(color: c.border),
          PostImpression(
            post: posts[i],
            child: CompactPostRow(
              post: posts[i],
              author: creator,
              now: now,
              showChevron: true,
              metaStyle: CompactPostMeta.sourceAndClock,
              onTap: () {
                final index = allPosts.indexWhere((p) => p.id == posts[i].id);
                PostViewerScreen.open(
                  context,
                  posts: index < 0 ? posts : allPosts,
                  initialIndex: index < 0 ? i : index,
                  authorOf: (_) => creator,
                  onOpenAuthor: (author) =>
                      CreatorScreen.open(context, author.id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
