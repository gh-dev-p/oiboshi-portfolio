import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_colors.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/search_field.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/state_view.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../home/widgets/home_tabs.dart';
import '../view_models/find_creators_viewmodel.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/creator_row.dart';
import '../../core/ui/viewer_aware_header.dart';
import '../../want/widgets/want_screen.dart';

/// 推しを探す（画面定義書 2.3.2・2.3.3）。
class FindCreatorsScreen extends ConsumerWidget {
  const FindCreatorsScreen({super.key});

  /// 推しのタブで開く（画面定義書 5.1.8）。
  static Future<void> open(BuildContext context) => HomeTabs.open(
    context,
    HomeTab.oshi,
    MaterialPageRoute<void>(builder: (_) => const FindCreatorsScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(findCreatorsViewModelProvider);
    final vm = ref.read(findCreatorsViewModelProvider.notifier);
    final now = DateTime.now();
    return HeaderScaffold(
      // 追星にいない人は、追いたい（画面定義書 2.3.4）で申告する。
      appBar: ScreenAppBar(
        title: l10n.commonFindCreatorsTitle,
        actions: [
          HeaderIconButton(
            icon: Icons.campaign_outlined,
            tooltip: l10n.wantTitle,
            onPressed: () => WantScreen.open(context),
          ),
        ],
      ),
      subheader: SearchField(
        hintText: l10n.commonSearch,
        onChanged: vm.setQuery,
      ),
      body: asyncBody(
        state.creators,
        loading: () => const CreatorListSkeleton(),
        error: () => StateView.error(onRetry: vm.retry),
        data: (list) {
          if (state.noMatch) {
            return StateView(
              icon: Icons.search,
              title: l10n.commonNotFound,
              message: l10n.commonFindNoMatch(state.resultQuery.trim()),
              buttonLabel: l10n.oshiFindWantButton,
              onPressed: () => WantScreen.open(
                context,
                initialText: state.resultQuery.trim(),
              ),
            );
          }
          return ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              // 見出しは、出している一覧がおすすめのときだけ（検索の結果が届くまでは、おすすめと一緒に残す）。
              if (state.showsRecommended)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Text(
                    l10n.oshiFindRecommended,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              for (final creator in list)
                CreatorRow(
                  creator: creator,
                  following: state.isFollowing(creator.id),
                  now: now,
                  avatarSize: 56,
                  onTap: () => CreatorScreen.open(context, creator.id),
                  onFollow: () async {
                    if (!await vm.toggleFollow(creator.id) && context.mounted) {
                      showAppSnackBar(context, l10n.commonFollowChangeFailed);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
