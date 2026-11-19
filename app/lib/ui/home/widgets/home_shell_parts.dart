import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../creator_admin/widgets/creator_menu_screen.dart';
import '../view_models/home_shell_sources_viewmodel.dart';

/// 発信者のタブの本体。自分の発信者の、発信者メニュー。発信者でなければ、何も出さない（タブも出さない）。
class HomeCreatorTab extends ConsumerWidget {
  const HomeCreatorTab({super.key, required this.onOpenSettings});

  /// 発信者メニューの歯車を押したとき。設定のタブへ移る。
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owned = ref
        .watch(homeShellSourcesViewModelProvider.select((s) => s.owned))
        .value;
    if (owned == null) return const SizedBox.shrink();
    return CreatorMenuScreen(
      creatorId: owned.id,
      onOpenSettings: onOpenSettings,
    );
  }
}

/// タブの中の画面の移り変わりを見て、ナビを元の大きさに戻すきっかけにする。いちばん上の画面も覚える。
class HomeRouteWatcher extends NavigatorObserver {
  HomeRouteWatcher({required this.onChanged});

  final VoidCallback onChanged;

  /// いちばん上の画面。
  Route<dynamic>? top;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    top = route;
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    top = previousRoute;
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route == top) top = previousRoute;
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == top) top = newRoute;
    onChanged();
  }
}

/// 隣のタブへ移っても、タブの画面（スクロールの位置や、積み重ねた画面）を残す。
class HomeKeepAlive extends StatefulWidget {
  const HomeKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<HomeKeepAlive> createState() => _HomeKeepAliveState();
}

class _HomeKeepAliveState extends State<HomeKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
