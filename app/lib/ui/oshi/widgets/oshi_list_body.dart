import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/oshi.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/follow_button.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/search_field.dart';
import '../../core/ui/state_view.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../core/view_models/playback_provider.dart';
import '../view_models/oshi_list_viewmodel.dart';
import 'find_creators_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/creator_row.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 推しリスト（画面定義書 2.3.1）。フォロー中の推しを一覧する。
class OshiListBody extends ConsumerWidget {
  const OshiListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(oshiListViewModelProvider.notifier);
    ref.listen(oshiListViewModelProvider.select((s) => s.entries), (
      prev,
      next,
    ) {
      if (isRefreshFailure(prev, next)) {
        showRefreshFailedSnackBar(context, vm.refresh);
      }
    });
    final state = ref.watch(oshiListViewModelProvider);
    final now = DateTime.now();
    final entries = state.entries;
    final loaded = entries.hasValue && !state.empty;
    final countHeader = loaded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
            child: Row(
              children: [
                Text(
                  l10n.oshiListCount(entries.value!.length),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.oshiListSortLiveFirst,
                  style: context.textStyles.note,
                ),
                const SizedBox(width: 4),
                Icon(Icons.swap_vert, size: 18, color: c.textSecondary),
              ],
            ),
          )
        : null;
    final header = ColoredBox(
      color: c.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 題名（「推しリスト」）は出さず、検索の欄をいちばん上に置く。「推し」の言葉を押し出さないため（2026-11-19 本人）。
          // 「推しを探す」のボタンは、検索の欄の右に置く。
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    hintText: l10n.commonSearch,
                    onChanged: vm.setQuery,
                    padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
                  ),
                ),
                HeaderIconButton(
                  icon: Icons.person_add_alt_1_outlined,
                  tooltip: l10n.commonFindCreatorsTitle,
                  onPressed: () => FindCreatorsScreen.open(context),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ?countHeader,
        ],
      ),
    );
    // 一覧のほかの表示（状態表示・スケルトン）は、ヘッダーの下の残りを埋める。
    Widget fill(Widget child) =>
        SliverFillRemaining(hasScrollBody: false, child: child);
    List<Widget> dataSlivers() {
      // フォロー中が0人なら、推しを探すへ誘う（画面定義書 2.3.1）。
      // 0人・結果なし・読み込めないときも、引き下げで読み直せる（画面定義書 2.3.1）。
      if (state.empty) {
        return [
          fill(
            StateView(
              icon: Icons.favorite_border,
              title: l10n.oshiListEmptyTitle,
              message: l10n.oshiListEmptyMessage,
              buttonLabel: l10n.commonFindCreatorsTitle,
              onPressed: () => FindCreatorsScreen.open(context),
            ),
          ),
        ];
      }
      // 検索に合う推しがいなければ、一覧の場所に出す（ボタンは置かない。画面定義書 5.1.3）。
      if (state.noMatch) {
        return [
          fill(
            StateView(
              icon: Icons.search,
              title: l10n.commonNotFound,
              message: l10n.oshiListNoMatch(state.query.trim()),
            ),
          ),
        ];
      }
      final rows = state.filtered;
      // 赤いリングは、ホームの推しレーンと同じく、配信ビューアで流している推しだけに付ける。
      final playback = ref.watch(playbackProvider);
      final playing = state.playingCreatorId(now, playback);
      return [
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          sliver: SliverList.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) => _OshiRow(
              entry: rows[i],
              now: now,
              playing: rows[i].oshi.id == playing,
              onUnfollow: () async {
                if (!await vm.unfollow(rows[i].oshi.id) && context.mounted) {
                  showAppSnackBar(context, l10n.oshiListUnfollowFailed);
                }
              },
            ),
          ),
        ),
      ];
    }

    // 読み込み方は asyncBody と同じ。読めなかったときは、「もう一度試す」のボタンも残す。
    final body = entries.hasValue
        ? dataSlivers()
        : entries.isLoading || !entries.hasError
        ? [fill(const CreatorListSkeleton())]
        : [fill(StateView.error(onRetry: vm.refresh))];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // 固定ビューアを出している間は、ヘッダー（タイトル・検索・人数と並び順）を固定せず、
        // 一覧と一緒にスクロールして上に隠す（画面定義書 2.3.1・5.1.2）。
        child: ViewerAwareHeader(
          header: header,
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            // 読み込み中は、引き下げで読み直さない（これまでと同じ）。
            notificationPredicate: (n) =>
                n.depth == 0 && (entries.hasValue || entries.hasError),
            child: CustomScrollView(
              // 中身が短くても、引き下げで読み直せるようにする。
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// 推しリストの1行。
class _OshiRow extends StatelessWidget {
  const _OshiRow({
    required this.entry,
    required this.now,
    required this.playing,
    required this.onUnfollow,
  });

  final OshiListEntry entry;
  final DateTime now;

  /// 固定ビューア・埋め込みビューアで流している推しか（赤いリングを付ける）。
  final bool playing;
  final VoidCallback onUnfollow;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final e = entry;
    final live = e.live;
    return InkWell(
      onTap: () => CreatorScreen.open(context, e.oshi.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ホームの推しレーンと同じリングと印。押すと、行と同じく発信者ページを開く。
            OshiAvatar(
              avatarUrl: e.oshi.creator.avatarUrl,
              size: 60,
              ring: playing ? OshiRing.live : OshiRing.read,
              badge: OshiBadge.fromRing(e.oshi.ringAt(now)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OneLineText(
                    e.oshi.creator.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (live != null)
                    OneLineText(
                      l10n.oshiListLiveNow(live.title),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: c.live,
                      ),
                    )
                  else if (e.next != null)
                    OneLineText(
                      l10n.oshiListNextSchedule(
                        scheduleLabel(e.next!.startsAt, now: now, l10n: l10n),
                        l10n.scheduleTitle(e.next!),
                      ),
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    )
                  else
                    Text(
                      l10n.oshiListNoSchedule,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FollowButton(following: true, onPressed: onUnfollow),
          ],
        ),
      ),
    );
  }
}
