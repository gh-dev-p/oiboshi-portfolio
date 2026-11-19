import 'package:flutter/material.dart';

/// 引き下げで読み直せる、一覧の場所いっぱいの表示（画面定義書 5.1.4）。
/// 空・結果なし・読み込めないの状態表示でも、引き下げで読み直せるように、場所の高さぶんスクロールできるようにする。
class RefreshableFill extends StatelessWidget {
  const RefreshableFill({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: box.maxHeight, child: child),
      ),
    ),
  );
}
