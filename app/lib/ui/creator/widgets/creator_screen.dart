import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/view_models/playback_provider.dart';

import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../home/widgets/home_tabs.dart';
import '../view_models/creator_viewmodel.dart';
import 'creator_profile_page.dart';

/// 発信者ページ（画面定義書 2.4.1）。配信中も、ページはいつもの見た目にし、アイコンに「LIVE」の印を付ける。
/// 配信は固定ビューアだけで流す。固定ビューアでその配信を流していなければ、「固定ビューアで見る」を出す（2026-11-19 本人）。
class CreatorScreen extends ConsumerWidget {
  const CreatorScreen({super.key, required this.creatorId});

  final String creatorId;

  /// 推しのタブで開く（画面定義書 5.1.8）。
  static Future<void> open(BuildContext context, String creatorId) =>
      HomeTabs.open(context, HomeTab.oshi, route(creatorId));

  /// 名前で発信者を見分け、同じ発信者のページを重ねないようにする。
  static Route<void> route(String creatorId) => MaterialPageRoute<void>(
    settings: RouteSettings(name: '/creator/$creatorId'),
    builder: (_) => CreatorScreen(creatorId: creatorId),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(creatorViewModelProvider(creatorId).notifier);
    ref.listen(creatorViewModelProvider(creatorId), (prev, next) {
      if (isRefreshFailure(prev, next)) {
        showRefreshFailedSnackBar(context, vm.refresh);
      }
    });
    final state = ref.watch(creatorViewModelProvider(creatorId));
    final now = DateTime.now();
    final playback = ref.watch(playbackProvider);
    // 固定ビューアで、いまこの推しの配信を流しているか（コントローラーで止めている間は、流していないとみなす）。
    final watching =
        playback is LivePlayback &&
        playback.creatorId == creatorId &&
        !ref.watch(fixedViewerPausedProvider);
    final body = asyncBody(
      state,
      data: (data) {
        final live = data.liveAt(now);
        // 配信が終わったと分かったら、固定ビューアを閉じる（ビルドの途中なので、次のフレームで）。
        if (live == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => vm.endLive());
        }
        return CreatorProfilePage(
          state: data,
          now: now,
          vm: vm,
          live: live != null,
          // 固定ビューアを閉じている・別の配信や動画を流している・止めているときは、押すとこの配信を固定ビューアで流す。
          onWatchLive: live == null || watching
              ? null
              : () {
                  if (playback is LivePlayback &&
                      playback.creatorId == creatorId) {
                    ref.read(fixedViewerPausedProvider.notifier).set(false);
                    return;
                  }
                  ref
                      .read(playbackProvider.notifier)
                      .play(
                        creatorId,
                        live,
                        avatarUrl: data.creator.avatarUrl,
                      );
                },
        );
      },
      loading: () => const _CreatorSkeleton(),
      error: () => StateView.error(onRetry: vm.refresh),
    );
    // 右へ払うと前の画面へ（iOS の標準の戻る）。ヘッダーは置かない。
    return Scaffold(body: body);
  }
}

class _CreatorSkeleton extends StatelessWidget {
  const _CreatorSkeleton();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 180 + top, radius: 0),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 160, height: 20),
              SizedBox(height: 8),
              SkeletonLine(width: 100),
              SizedBox(height: 12),
              SkeletonLine(),
              SizedBox(height: 8),
              SkeletonLine(width: 240),
            ],
          ),
        ),
      ],
    );
  }
}
