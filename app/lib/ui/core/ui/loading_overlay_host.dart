import 'package:flutter/material.dart';

/// 全画面共通の処理中の表示。[visible] の間、薄暗い背景を重ねてタップをブロックする。
/// 一瞬で終わる処理でちらつかないよう、少し遅らせてから見せる。
class LoadingOverlayHost extends StatelessWidget {
  const LoadingOverlayHost({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (visible)
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: const Interval(0.5, 1),
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
              child: const ModalBarrier(
                dismissible: false,
                color: Colors.black26,
              ),
            ),
          ),
      ],
    );
  }
}
