import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/provider_retry.dart';
import 'package:oiboshi/l10n/app_localizations.dart';
import 'package:oiboshi/ui/core/themes/app_theme.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';

import '../fakes.dart';

/// [testApp] で [home] を出し、落ち着くまで進める。
Future<void> pumpScreen(
  WidgetTester tester,
  FakeData data,
  Widget home, {
  FakeNotificationRepository? notification,
  FakeImagePickerService? picker,
  FakeAppLinkService? links,
  FakeShareSheetService? shareSheet,
  FakeClipboardService? clipboard,
  FakeReachRepository? reach,
  FakePostViewRepository? postViews,
  Locale? locale = const Locale('ja'),
}) async {
  await tester.pumpWidget(
    await testApp(
      data,
      home,
      notification: notification,
      picker: picker,
      links: links,
      shareSheet: shareSheet,
      clipboard: clipboard,
      reach: reach,
      postViews: postViews,
      locale: locale,
    ),
  );
  await tester.pumpAndSettle();
}

/// 1分ごとの読み直しのタイマーを止めるため、最後に画面を外す。
/// テストの本体が終わったあとの「残ったタイマー」の確かめは、`addTearDown` より先に走る。
/// そのため、`addTearDown` には移さず、テストの最後で呼ぶ。
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

/// スマホの画面の大きさ（iPhone の 1170×2532、倍率3）にする。テストのあとで戻す。
void usePhoneScreen(WidgetTester tester, {Size size = const Size(1170, 2532)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// 200ミリ秒ずつ5回進める。動画や配信のプレイヤーが動き続けて
/// `pumpAndSettle` が終わらない画面で使う。
Future<void> settleFrames(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// ホーム（[HomeShell]）の `ProviderContainer`。
ProviderContainer homeContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(HomeShell)));

/// Repository を使わない部品のテスト用。アプリと同じテーマで、日本語で [home] を出す。
Widget localizedApp(Widget home) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('ja'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// 「開く」ボタンだけの前の画面。押すと [onOpen] で画面を開く。
/// 閉じたときに前の画面へ戻るのを確かめるのに使う。
Widget opener(void Function(BuildContext context) onOpen) => Builder(
  builder: (context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => onOpen(context),
        child: const Text('開く'),
      ),
    ),
  ),
);

/// [opener] を [testApp] で出し、「開く」を押して、落ち着くまで進める。
Future<void> pumpOpener(
  WidgetTester tester,
  FakeData data,
  void Function(BuildContext context) onOpen, {
  FakeImagePickerService? picker,
}) async {
  await pumpScreen(tester, data, opener(onOpen), picker: picker);
  await tapOpen(tester);
}

/// [opener] の「開く」を押して、落ち着くまで進める。
Future<void> tapOpen(WidgetTester tester) async {
  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
}

/// ViewModel のテスト用の `ProviderContainer`。Repository を [data] のフェイクにし、テストのあとで捨てる。
Future<ProviderContainer> testContainer(
  FakeData data, {
  FakeNotificationRepository? notification,
  FakeShareSheetService? shareSheet,
  List<Override> overrides = const [],
}) async {
  final container = ProviderContainer(
    retry: noProviderRetry,
    overrides: [
      ...await testOverrides(
        data,
        notification: notification,
        shareSheet: shareSheet,
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}
