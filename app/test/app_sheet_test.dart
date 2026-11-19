import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/themes/app_theme.dart';
import 'package:oiboshi/ui/core/ui/app_sheet.dart';
import 'package:oiboshi/ui/core/ui/app_snack_bar.dart';

/// タブの Navigator と、その上の層の下部ナビ（home_shell.dart と同じ形）。
Widget _shell() => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Stack(
      children: [
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () =>
                    showAppSheet<void>(context, builder: (_) => const _Sheet()),
                child: const Text('開く'),
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 80,
          child: ColoredBox(color: Colors.blue, child: Text('下部ナビ')),
        ),
      ],
    ),
  ),
);

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('シートの文'),
          TextButton(
            onPressed: () => showAppSnackBar(context, 'シートのスナックバー'),
            child: const Text('一番下のボタン'),
          ),
        ],
      ),
    );
  }
}

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(_shell());
  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('タブの中から開いても、シートを下部ナビの前に重ねる', (tester) async {
    await _open(tester);
    // 一番上の Navigator に積む。
    final route = ModalRoute.of(tester.element(find.text('シートの文')))!;
    expect(
      route.navigator,
      tester.state<NavigatorState>(find.byType(Navigator).first),
    );
    // 下部ナビと重なる位置のボタンも押せる（下部ナビに隠れていない）。
    final button = tester.getRect(find.text('一番下のボタン'));
    final nav = tester.getRect(find.text('下部ナビ').first);
    expect(button.bottom, greaterThan(nav.top));
    await tester.tap(find.text('一番下のボタン'));
    await tester.pump();
    expect(find.text('シートのスナックバー'), findsOneWidget);
  });

  testWidgets('シートの中で出したスナックバーは、シートの上の端に出し、シートのボタンを覆わない', (tester) async {
    await _open(tester);
    await tester.tap(find.text('一番下のボタン'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('シートのスナックバー'),
      ),
      findsOneWidget,
    );
    final snackBar = tester.getRect(find.byType(SnackBar));
    expect(
      snackBar.bottom,
      lessThanOrEqualTo(tester.getRect(find.text('シートの文')).top),
    );
    // 続けて押せる。
    await tester.tap(find.text('一番下のボタン'));
    await tester.pump();
  });

  testWidgets('シートの外を押すと閉じ、シートの中を押しても閉じない', (tester) async {
    await _open(tester);
    await tester.tap(find.text('シートの文'));
    await tester.pumpAndSettle();
    expect(find.text('シートの文'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('シートの文'), findsNothing);
  });

  testWidgets('戻る操作で閉じる', (tester) async {
    await _open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('シートの文'), findsNothing);
  });
}
