import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/onboarding/widgets/choose_oshi_screen.dart';
import 'package:oiboshi/ui/onboarding/widgets/welcome_screen.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

const _link = 'https://oiboshi.perrii.app/c/minato';

/// 入れたあとの引き継ぎ（届ける・広める仕様書 4.3.4）。
void main() {
  late FakeData data;

  setUp(() {
    data = FakeData()
      ..creators.add(sampleCreator())
      ..posts.add(samplePost());
  });

  Future<void> start(
    WidgetTester tester,
    FakeClipboardService clipboard,
  ) async {
    await pumpScreen(tester, data, const WelcomeScreen(), clipboard: clipboard);
    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
  }

  testWidgets('共有のリンクがあれば、推しを選ぶの前に発信者ページを出し、戻ると推しを選ぶ', (tester) async {
    final clipboard = FakeClipboardService(text: _link);
    await start(tester, clipboard);
    expect(find.byType(CreatorScreen), findsOneWidget);
    expect(find.byType(ChooseOshiScreen), findsNothing);
    expect(data.clipboardLinkChecked, isTrue);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.byType(ChooseOshiScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('誘う用のリンクなら、その発信者をフォローしてからページを出し、知らせる（4.3.6）', (tester) async {
    final clipboard = FakeClipboardService(text: '$_link?invite=1');
    await start(tester, clipboard);
    expect(find.byType(CreatorScreen), findsOneWidget);
    expect(data.follows.map((f) => f.creatorId), ['minato']);
    expect(find.text('星野ミナトをフォローしました'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ふつうの共有のリンクでは、フォローしない', (tester) async {
    final clipboard = FakeClipboardService(text: _link);
    await start(tester, clipboard);
    expect(find.byType(CreatorScreen), findsOneWidget);
    expect(data.follows, isEmpty);
    await unmount(tester);
  });

  testWidgets('URL らしいものがなければ、中身を読まずに推しを選ぶへ進む', (tester) async {
    final clipboard = FakeClipboardService(text: 'こんにちは');
    await start(tester, clipboard);
    expect(clipboard.reads, 0);
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.byType(ChooseOshiScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ほかの URL は使わない', (tester) async {
    final clipboard = FakeClipboardService(
      text: 'https://example.com/c/minato',
    );
    await start(tester, clipboard);
    expect(clipboard.reads, 1);
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.byType(ChooseOshiScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('貼り付けを許可されなければ、引き継がない', (tester) async {
    final clipboard = FakeClipboardService(text: _link, allowPaste: false);
    await start(tester, clipboard);
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.byType(ChooseOshiScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('発信者がない・ファンに見せないなら、引き継がない', (tester) async {
    data.unshareableCreatorIds.add('minato');
    final clipboard = FakeClipboardService(text: _link);
    await start(tester, clipboard);
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.byType(ChooseOshiScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('確かめるのは1回だけ（2回目の「はじめる」では読まない）', (tester) async {
    data.clipboardLinkChecked = true;
    final clipboard = FakeClipboardService(text: _link);
    await start(tester, clipboard);
    expect(clipboard.reads, 0);
    expect(find.byType(CreatorScreen), findsNothing);
    expect(find.byType(ChooseOshiScreen), findsOneWidget);
    await unmount(tester);
  });
}
