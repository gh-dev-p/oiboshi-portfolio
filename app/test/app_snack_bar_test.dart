import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/themes/app_theme.dart';
import 'package:oiboshi/ui/core/ui/app_snack_bar.dart';

Future<void> _show(
  WidgetTester tester,
  String message, {
  String? actionLabel,
}) async {
  // iPhone と同じくらいの幅にする。
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showAppSnackBar(
                context,
                message,
                actionLabel: actionLabel,
                onAction: actionLabel == null ? null : () {},
              ),
              child: const Text('出す'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('出す'));
  await tester.pumpAndSettle();
}

/// 通知の面（色の付いた部分）。
final _surface = find
    .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
    .first;

void main() {
  testWidgets('短い文は、横幅いっぱいにせず、文字に合った幅で中央に出す', (tester) async {
    await _show(tester, '保存しました');
    final screen = tester.getSize(find.byType(Scaffold));
    final bar = tester.getRect(_surface);
    expect(bar.width, lessThan(screen.width / 2));
    expect(bar.center.dx, moreOrLessEquals(screen.width / 2));
    // 1行に収まる。
    final text = tester.getRect(find.text('保存しました'));
    expect(text.height, lessThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('長い文は、画面の端から少し内側までの幅で折り返す', (tester) async {
    const message = '発信者として登録しました。プロフィールの一部を保存できなかったので、プロフィールの編集で直してください';
    await _show(tester, message);
    final screen = tester.getSize(find.byType(Scaffold));
    final bar = tester.getRect(_surface);
    expect(bar.width, moreOrLessEquals(screen.width - 30));
    expect(bar.center.dx, moreOrLessEquals(screen.width / 2));
    expect(tester.getRect(find.text(message)).height, greaterThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('操作のある文は、操作を文の右に並べ、1行に収める', (tester) async {
    await _show(tester, '更新できませんでした', actionLabel: '再試行');
    final screen = tester.getSize(find.byType(Scaffold));
    final bar = tester.getRect(_surface);
    expect(bar.width, lessThan(screen.width - 30));
    final text = tester.getRect(find.text('更新できませんでした'));
    final action = tester.getRect(find.text('再試行'));
    expect(text.height, lessThan(30));
    expect(action.left, greaterThan(text.right));
    expect(action.center.dy, moreOrLessEquals(text.center.dy, epsilon: 2));
    expect(tester.takeException(), isNull);
  });
}
