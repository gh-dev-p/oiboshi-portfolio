import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 下部ナビのタブ。[creator] のほかは、並びの順。[creator]（発信者のタブ）は、発信者だけ、楕円から切り離して左に出す。
enum HomeTab { home, schedule, oshi, settings, creator }

/// ホームの枠の状態（選択中のタブと、下部ナビを縮小しているか）。
class HomeShellState {
  const HomeShellState({this.tab = HomeTab.home, this.navCollapsed = false});

  final HomeTab tab;

  /// 下部ナビを縮小しているか（下にスクロールしたとき）。
  final bool navCollapsed;

  HomeShellState copyWith({HomeTab? tab, bool? navCollapsed}) => HomeShellState(
    tab: tab ?? this.tab,
    navCollapsed: navCollapsed ?? this.navCollapsed,
  );
}

class HomeShellViewModel extends Notifier<HomeShellState> {
  @override
  HomeShellState build() => const HomeShellState();

  /// タブを選ぶ。同じタブなら true を返し、View がそのタブの最初の画面に戻す。
  bool selectTab(HomeTab tab) {
    final same = tab == state.tab;
    state = state.copyWith(tab: tab, navCollapsed: false);
    return same;
  }

  void setNavCollapsed(bool collapsed) {
    if (state.navCollapsed != collapsed) {
      state = state.copyWith(navCollapsed: collapsed);
    }
  }
}

final homeShellViewModelProvider =
    NotifierProvider<HomeShellViewModel, HomeShellState>(
      HomeShellViewModel.new,
    );
