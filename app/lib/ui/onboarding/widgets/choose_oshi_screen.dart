import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/search_field.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/state_view.dart';
import '../view_models/choose_oshi_viewmodel.dart';
import 'notification_intro_screen.dart';
import 'welcome_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/creator_row.dart';

/// 推しを選ぶ（画面定義書 2.1.2）。最初にフォローする推しを選ぶ。
class ChooseOshiScreen extends ConsumerWidget {
  const ChooseOshiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(chooseOshiViewModelProvider);
    final vm = ref.read(chooseOshiViewModelProvider.notifier);
    final followed = state.followedIds;
    final now = DateTime.now();

    void next() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationIntroScreen()),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.onboardingChooseTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.onboardingChooseMessage,
                    style: context.textStyles.note,
                  ),
                ],
              ),
            ),
            SearchField(
              hintText: l10n.onboardingChooseSearchHint,
              onChanged: vm.setQuery,
            ),
            Expanded(
              child: asyncBody(
                state.creators,
                loading: () => const CreatorListSkeleton(),
                error: () => StateView.error(onRetry: vm.retry),
                data: (list) => state.noMatch
                    // 推しを探す（結果なし。画面定義書 2.3.3）と同じ状態表示。
                    ? StateView(
                        icon: Icons.search,
                        title: l10n.commonNotFound,
                        message: l10n.commonFindNoMatch(
                          state.resultQuery.trim(),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: list.length,
                        itemBuilder: (context, i) => CreatorRow(
                          creator: list[i],
                          following: state.isFollowing(list[i].id),
                          now: now,
                          onFollow: () async {
                            if (!await vm.toggleFollow(list[i].id) &&
                                context.mounted) {
                              showAppSnackBar(
                                context,
                                l10n.commonFollowChangeFailed,
                              );
                            }
                          },
                        ),
                      ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: c.background,
                border: Border(top: BorderSide(color: c.border)),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.paddingOf(context).bottom + 8,
              ),
              child: Column(
                children: [
                  OnboardingPrimaryButton(
                    label: followed.isEmpty
                        ? l10n.onboardingNext
                        : l10n.onboardingNextFollowing(followed.length),
                    onPressed: next,
                  ),
                  const SizedBox(height: 2),
                  AppTextButton(
                    label: l10n.onboardingLater,
                    onPressed: next,
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
