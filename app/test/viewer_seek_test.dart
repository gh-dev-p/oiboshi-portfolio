import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/l10n/app_localizations.dart';
import 'package:oiboshi/ui/core/themes/app_theme.dart';
import 'package:oiboshi/ui/core/ui/app_bottom_nav.dart';
import 'package:oiboshi/ui/core/ui/viewer_control.dart';

/// 動画シャッフルのとき、コントローラーを左右に引っ張ったまま止めて、早送り・巻き戻しする（機能仕様書 4.3.5）。
void main() {
  group('速さと端', () {
    test('最初は1秒に5秒分、1秒ごとに速くなり、最大で1秒に60秒分', () {
      int at(int ms) => ViewerSeek.speedAt(Duration(milliseconds: ms));
      expect(at(0), 5);
      expect(at(999), 5);
      expect(at(1000), 10);
      expect(at(2000), 20);
      expect(at(3000), 40);
      expect(at(4000), 60);
      expect(at(60000), 60);
    });

    test('動画の頭と、終わりの手前で止まる', () {
      const duration = Duration(minutes: 3);
      expect(
        ViewerSeek.clamp(const Duration(seconds: -5), duration),
        Duration.zero,
      );
      expect(
        ViewerSeek.clamp(const Duration(seconds: 90), duration),
        const Duration(seconds: 90),
      );
      expect(
        ViewerSeek.clamp(const Duration(minutes: 5), duration),
        duration - ViewerSeek.endMargin,
      );
    });
  });

  group('払う・引っ張ったまま止める', () {
    late List<ViewerControl> controls;
    late List<String> seeks;
    late bool canSeek;

    Future<void> pump(WidgetTester tester) async {
      controls = [];
      seeks = [];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomNav(
                currentIndex: 0,
                onTap: (_) {},
                viewer: (
                  on: true,
                  paused: false,
                  live: false,
                  newVideo: false,
                  onTap: () {},
                  onControl: controls.add,
                  seek: (
                    start: (direction) {
                      seeks.add('start $direction');
                      return canSeek;
                    },
                    direction: (direction) => seeks.add('direction $direction'),
                    end: () => seeks.add('end'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// コントローラー（固定ビューアのスイッチ）の真ん中。
    Offset controller(WidgetTester tester) =>
        tester.getCenter(find.bySemanticsLabel('固定ビューア').first);

    testWidgets('さっと払うと、今までどおり次', (tester) async {
      canSeek = true;
      await pump(tester);
      final gesture = await tester.startGesture(controller(tester));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(controls, [ViewerControl.next]);
      expect(seeks, isEmpty);
    });

    testWidgets('右に引っ張ったまま止めると早送り、離すとそこから再生し、次にはしない', (tester) async {
      canSeek = true;
      await pump(tester);
      final gesture = await tester.startGesture(controller(tester));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump(ViewerSeek.holdDelay);
      expect(seeks, ['start 1']);
      // 左に引っ張り直すと、巻き戻し。
      await gesture.moveBy(const Offset(-120, 0));
      await tester.pump();
      expect(seeks, ['start 1', 'direction -1']);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(seeks, ['start 1', 'direction -1', 'end']);
      expect(controls, isEmpty);
    });

    testWidgets('始められない（配信など）ときは、引っ張ったまま止めても今までどおり前', (tester) async {
      canSeek = false;
      await pump(tester);
      final gesture = await tester.startGesture(controller(tester));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(seeks, ['start -1']);
      expect(controls, [ViewerControl.previous]);
    });

    testWidgets('上に引っ張ったまま止めても、早送りにはしない', (tester) async {
      canSeek = true;
      await pump(tester);
      final gesture = await tester.startGesture(controller(tester));
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveBy(const Offset(0, -30));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(seeks, isEmpty);
      expect(controls, [ViewerControl.playPause]);
    });
  });
}
