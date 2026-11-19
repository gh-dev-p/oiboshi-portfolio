import 'dart:ui';

import 'package:flutter/material.dart';

/// 下部ナビの、透明度の高いすりガラス（タイムスケジュールの浮かせたボタンにも使う。「写真」の下部メニューに寄せる）。後ろの中身が、ぼけて透けて見える。
/// ふちは、外側に暗い細い線、内側に白く光る線を引き、ガラスの厚みを出す（「写真」のふちの 2px と同じ並び）。
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const shape = StadiumBorder();
    return Container(
      width: width,
      height: height,
      // ふちのいちばん外側の、暗い細い線（「写真」の 1px）。
      foregroundDecoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: Colors.black.withValues(alpha: dark ? 0.5 : 0.3),
            width: 0.4,
          ),
        ),
      ),
      decoration: ShapeDecoration(
        shape: shape,
        shadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.035),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              // 影が透けて暗くならないよう、白を濃いめにする（「写真」と同じく、背景よりわずかに暗くなる）。
              color: dark
                  ? Colors.black.withValues(alpha: 0.32)
                  : Colors.white.withValues(alpha: 0.62),
              // 暗い線のすぐ内側の、白く光る線（「写真」の 1px）。
              shape: StadiumBorder(
                side: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? 0.22 : 0.9),
                  width: 0.8,
                ),
              ),
            ),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    );
  }
}
