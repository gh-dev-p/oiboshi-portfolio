import 'package:flutter/material.dart';

/// 何枚目か（何人目か）を表す点。見ている枚を濃くする。投稿ビューアのカルーセルと、配信の帯で使う。
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.index,
    this.color = Colors.white,
  });

  final int count;
  final int index;

  /// 見ている枚の点の色。ほかの点は、この色を薄くする。
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index ? color : color.withValues(alpha: 0.4),
            ),
          ),
      ],
    );
  }
}
