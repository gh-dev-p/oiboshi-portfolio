import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/post.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/post_cards.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../../post/widgets/post_viewer_screen.dart';
import '../view_models/post_manage_viewmodel.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 投稿の管理（画面定義書（設定・発信者向け）2.3.8）。自分の投稿を一覧し、行ごとのトグルで隠す・また出す（機能仕様書 4.4.4）。
class PostManageScreen extends ConsumerWidget {
  const PostManageScreen({super.key, required this.creatorId});

  final String creatorId;

  /// [post] を隠す（[hidden] が真）・また出す。取り消せるので、確認のダイアログは出さない。
  Future<void> _setHidden(
    BuildContext context,
    WidgetRef ref,
    Post post, {
    required bool hidden,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(postManageViewModelProvider(creatorId).notifier);
    final done = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => vm.setHidden(post, hidden: hidden));
    if (!context.mounted) return;
    showAppSnackBar(context, switch ((hidden, done)) {
      (true, true) => l10n.creatorAdminPostHidden,
      (true, false) => l10n.creatorAdminPostHideFailed,
      (false, true) => l10n.creatorAdminPostShown,
      (false, false) => l10n.creatorAdminPostShowFailed,
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(postManageViewModelProvider(creatorId));
    // X の投稿の行（X の投稿者の行）に、自分の発信者のアイコン・名前を出す。
    final creator = state.creator;
    final now = DateTime.now();
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.creatorAdminPostManageTitle),
      body: state.posts.when(
        skipLoadingOnRefresh: true,
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              SkeletonLine(),
              SizedBox(height: 16),
              SkeletonLine(),
              SizedBox(height: 16),
              SkeletonLine(),
            ],
          ),
        ),
        error: (_, _) => StateView.error(
          onRetry: ref
              .read(postManageViewModelProvider(creatorId).notifier)
              .retry,
        ),
        data: (posts) => posts.isEmpty
            ? StateView(
                icon: Icons.article_outlined,
                title: l10n.commonNoPostsYet,
                message: '',
              )
            : ListView.builder(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 32,
                ),
                // 先頭は、隠しても元の SNS の投稿は消えないことの注記。
                itemCount: posts.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        l10n.creatorAdminPostManageNote,
                        style: context.textStyles.note,
                      ),
                    );
                  }
                  final post = posts[i - 1];
                  final hidden = state.hiddenIds.contains(post.id);
                  return Row(
                    children: [
                      Expanded(
                        // 隠している投稿は、行を薄くする。
                        child: Opacity(
                          opacity: hidden ? 0.4 : 1,
                          child: CompactPostRow(
                            post: post,
                            now: now,
                            author: creator,
                            // この一覧の順で、前後に移る。投稿者は自分なので、押せない。
                            onTap: () => PostViewerScreen.open(
                              context,
                              posts: posts,
                              initialIndex: i - 1,
                              authorOf: (_) => creator,
                            ),
                          ),
                        ),
                      ),
                      // オン＝ファンに出す、オフ＝隠す。できるまで切り替えず、できなければ元のまま。
                      Semantics(
                        label: l10n.creatorAdminPostVisibleSwitch,
                        child: AppSwitch(
                          value: !hidden,
                          onChanged: (visible) =>
                              _setHidden(context, ref, post, hidden: !visible),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
