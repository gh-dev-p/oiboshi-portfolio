import 'package:flutter/material.dart';

import '../themes/app_colors.dart';

/// 読み込み中のスケルトン（画面定義書 5.1.3）。画面の形に合わせた灰色の骨組み。
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.circle = false,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceVariant,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// 文字の行のスケルトン。
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.width, this.height = 12});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: width, height: height, radius: height / 2);
}

/// アイコン・2行の文字・右のボタンの行のスケルトン（ログイン方法・アカウント連携の行）。
class SkeletonIconRow extends StatelessWidget {
  const SkeletonIconRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SkeletonBox(width: 36, height: 36, circle: true),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 96, height: 14),
                SizedBox(height: 6),
                SkeletonLine(width: 140, height: 10),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 72, height: 30),
        ],
      ),
    );
  }
}
