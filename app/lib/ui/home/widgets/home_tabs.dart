import 'package:flutter/widgets.dart';

import '../view_models/home_shell_viewmodel.dart';

// タブの種類は ViewModel 層に置く（依存は View → ViewModel の向きだけ）。ほかの機能の View は、
// これまでどおり、このファイルから使えるようにする。
export '../view_models/home_shell_viewmodel.dart' show HomeTab;

/// 画面を、受け持ちのタブで開く（画面定義書 5.1.8）。ホームの枠（HomeShell）が、タブの中の画面の上に置く。
/// 同じタブの中からはいまの画面の上に重ね、ほかのタブからは、受け持ちのタブへ移って、その最初の画面の上に開く。
class HomeTabs extends InheritedWidget {
  const HomeTabs({
    super.key,
    required this.current,
    required this.onOpen,
    required this.onShowRoot,
    required super.child,
  });

  /// いま選んでいるタブ。
  final HomeTab current;

  /// [from] は、押した画面の Navigator（タブの外なら null）。
  final Future<void> Function(
    NavigatorState? from,
    HomeTab tab,
    Route<void> route,
  )
  onOpen;

  /// [tab] のタブを、最初の画面に戻してから出す（下部ナビで同じタブを押したときと同じ戻し方）。
  final void Function(HomeTab tab) onShowRoot;

  /// [tab] のタブで [route] を開く。ホームの枠の外（テストで画面だけを出したときなど）では、いまの Navigator に重ねる。
  static Future<void> open(
    BuildContext context,
    HomeTab tab,
    Route<void> route,
  ) {
    final scope = context.getInheritedWidgetOfExactType<HomeTabs>();
    if (scope == null) return Navigator.of(context).push(route);
    return scope.onOpen(Navigator.maybeOf(context), tab, route);
  }

  /// [tab] のタブを最初の画面に戻して出す（ホームの「次の予定」の「ほか N 件」など）。
  /// ホームの枠の外では、何もしない。
  static void showRoot(BuildContext context, HomeTab tab) =>
      context.getInheritedWidgetOfExactType<HomeTabs>()?.onShowRoot(tab);

  /// [context] が入っているタブ。タブの外（タブの上に重ねた画面・ホームの枠の外）なら null。
  static HomeTab? tabOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<HomeTabScope>()?.tab;

  /// いま選んでいるタブ。タブが変わると、[context] を作り直す。ホームの枠の外なら null。
  static HomeTab? currentOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeTabs>()?.current;

  @override
  bool updateShouldNotify(HomeTabs oldWidget) => current != oldWidget.current;
}

/// タブの Navigator を包み、中の画面に、どのタブにいるかを伝える（[HomeTabs.tabOf]）。
class HomeTabScope extends InheritedWidget {
  const HomeTabScope({super.key, required this.tab, required super.child});

  final HomeTab tab;

  @override
  bool updateShouldNotify(HomeTabScope oldWidget) => tab != oldWidget.tab;
}
