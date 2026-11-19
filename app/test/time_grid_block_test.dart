import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/schedule_layout.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/schedule/widgets/time_grid_items.dart';

import 'helpers/widget_helpers.dart';

void main() {
  // 終了のない公演はその日の終わりまで伸びるので、配信と重なって半分の幅になりやすい（2026-11-19 本人）。
  // 半分の幅の1時間ほどのブロックでも、中身がはみ出さない（はみ出すと、組み立ての例外になる）。
  for (final height in [46.0, 52.0, 60.0, 66.0, 74.0, 84.0, 96.0, 120.0]) {
    testWidgets('半分の幅のブロックは、高さ $height でもはみ出さない', (tester) async {
      final start = DateTime(2026, 12, 27, 21);
      await tester.pumpWidget(
        localizedApp(
          Center(
            child: SizedBox(
              width: 56,
              height: height,
              child: TimeGridBlock(
                block: ScheduleBlock(
                  creatorId: 'minato',
                  title: '【確認用】終了のない配信のとても長いタイトル',
                  start: start,
                  end: start.add(const Duration(hours: 1)),
                  openEnded: true,
                  service: SnsService.youtube,
                  isLiveNow: false,
                ),
                expanded: true,
                half: true,
                now: DateTime(2026, 12, 1),
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
