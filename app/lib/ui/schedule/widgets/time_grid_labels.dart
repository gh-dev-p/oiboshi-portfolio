import 'package:flutter/material.dart';

import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import 'time_grid.dart';

/// 時刻のラベルを出す間隔（時間）。1時間の高さが小さいほど、間を空ける。
int labelStepFor(double hourHeight) => hourHeight >= 36
    ? 1
    : hourHeight >= 18
    ? 2
    : 3;

/// 時刻のラベルと、現在時刻のタグ。
class TimeGridLabels extends StatelessWidget {
  const TimeGridLabels({
    super.key,
    required this.hourHeight,
    required this.now,
  });

  final double hourHeight;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final step = labelStepFor(hourHeight);
    final now = this.now;
    final nowY = now == null ? null : (now.hour + now.minute / 60) * hourHeight;
    return SizedBox(
      height: hourHeight * 24,
      width: TimeGrid.labelWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 端が分かるように、24:00 も出す。
          for (var h = 0; h <= 24; h += step)
            if (nowY == null || (h * hourHeight - nowY).abs() > 10)
              Positioned(
                left: 0,
                right: 6,
                top: h * hourHeight - 7,
                child: Text(
                  '$h:00',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 10, color: c.textTertiary),
                ),
              ),
          if (nowY != null) ...[
            Positioned(
              left: 36,
              top: nowY - 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.now),
              ),
            ),
            Positioned(
              left: 0,
              top: nowY - 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: c.now,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  clockTime(now!),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TimeGridLinesPainter extends CustomPainter {
  TimeGridLinesPainter({
    required this.hourHeight,
    required this.major,
    required this.minor,
  });

  final double hourHeight;
  final Color major;
  final Color minor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..strokeWidth = 1;
    final step = labelStepFor(hourHeight);
    for (var h = 0; h <= 24; h++) {
      paint.color = h % step == 0 ? major : minor;
      final y = h * hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(TimeGridLinesPainter old) =>
      old.hourHeight != hourHeight || old.major != major || old.minor != minor;
}
