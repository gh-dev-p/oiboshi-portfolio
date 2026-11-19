import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_register_screen.dart';
import 'package:oiboshi/ui/onboarding/view_models/onboarding_providers.dart';
import 'package:oiboshi/ui/onboarding/widgets/choose_oshi_screen.dart';
import 'package:oiboshi/ui/onboarding/widgets/notification_intro_screen.dart';
import 'package:oiboshi/ui/onboarding/widgets/welcome_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  testWidgets('ウェルカムの「利用規約」はリンクで、開けなければスナックバーで知らせる', (tester) async {
    await pumpScreen(tester, data, const WelcomeScreen());
    await tester.tapOnText(find.textRange.ofSubstring('利用規約'));
    // URL を開く処理は、プラットフォームの応答を本当の時間で待つ。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    // テストには URL を開く先がないので、開けなかったときの知らせが出る。
    expect(find.text('ページを開けませんでした'), findsOneWidget);
    expect(find.text('推しをフォローしましょう'), findsNothing);
  });

  testWidgets('ウェルカムの「発信者の方はこちら」は、匿名なら先にアカウント作成／ログインを出し、作ったら登録へ進む', (
    tester,
  ) async {
    await pumpScreen(tester, data, const WelcomeScreen());
    await tester.tap(find.text('発信者の方はこちら'));
    await tester.pumpAndSettle();
    expect(find.text('発信者として登録するには、アカウントが要ります。'), findsOneWidget);
    // 閉じたら、登録へは進まない。
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorRegisterScreen), findsNothing);

    await tester.tap(find.text('発信者の方はこちら'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Twitchで続ける'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorRegisterScreen), findsOneWidget);
    expect(data.loginMethods.single.provider, LoginProvider.twitch);
    await unmount(tester);
  });

  testWidgets('ウェルカムの「発信者の方はこちら」で、もう発信者のアカウントにログインしたら、登録へは進まない', (
    tester,
  ) async {
    data
      ..loginResult = LoginResult.alreadyUsed
      ..signInResult = LoginResult.done
      ..ownedCreatorId = 'minato';
    await pumpScreen(tester, data, const WelcomeScreen());
    await tester.tap(find.text('発信者の方はこちら'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Google で続行'));
    await tester.pumpAndSettle();
    expect(find.text('ログインしました'), findsOneWidget);
    expect(find.byType(CreatorRegisterScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('「はじめる」を連打しても、推しを選ぶは1枚だけ開く', (tester) async {
    await pumpScreen(tester, data, const WelcomeScreen());
    // 作り直す前（同じフレームの中）に、2回押す。
    final onPressed = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    onPressed();
    onPressed();
    await tester.pump();
    // 処理中は、押せない。
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ChooseOshiScreen, skipOffstage: false), findsOneWidget);

    // 戻ると、また押せる。
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(find.byType(ChooseOshiScreen, skipOffstage: false), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しを選ぶで、検索に合う発信者がいなければ、推しを探すと同じ状態表示を出す', (tester) async {
    await pumpScreen(tester, data, const WelcomeScreen());
    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ほしのミナ');
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();
    expect(find.text('見つかりませんでした'), findsOneWidget);
    expect(find.textContaining('「ほしのミナ」に合う推しは、まだ追星にいません。'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('初回起動は、ウェルカム・推しを選ぶ・通知の説明の順に進み、ホームに着く', (tester) async {
    final notification = FakeNotificationRepository();
    await pumpScreen(
      tester,
      data,
      const WelcomeScreen(),
      notification: notification,
    );
    expect(find.text('追星'), findsOneWidget);

    await tester.tap(find.text('はじめる'));
    await tester.pumpAndSettle();
    expect(find.text('推しをフォローしましょう'), findsOneWidget);
    expect(find.text('星野ミナト'), findsOneWidget);

    await tester.tap(find.text('フォロー'));
    await tester.pumpAndSettle();
    expect(find.text('フォロー中'), findsOneWidget);
    expect(find.text('次へ（1人をフォロー中）'), findsOneWidget);

    await tester.tap(find.text('次へ（1人をフォロー中）'));
    await tester.pumpAndSettle();
    expect(find.text('配信が始まったら、\nお知らせします'), findsOneWidget);

    await tester.tap(find.text('通知をオンにする'));
    await tester.pumpAndSettle();
    expect(notification.requests, 1);
    expect(data.onboardingDone, isTrue);
    await unmount(tester);
  });

  testWidgets('通知の説明のボタンを連打しても、許可の要求は1回だけ', (tester) async {
    final notification = FakeNotificationRepository();
    await pumpScreen(
      tester,
      data,
      const NotificationIntroScreen(),
      notification: notification,
    );
    // 作り直す前（同じフレームの中）に、両方のボタンを押す。
    final enable = tester
        .widget<FilledButton>(find.byType(FilledButton))
        .onPressed!;
    final skip = tester
        .widget<TextButton>(find.widgetWithText(TextButton, 'いまはしない'))
        .onPressed!;
    enable();
    enable();
    skip();
    await tester.pump();
    // 処理中は、どちらも押せない。
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'いまはしない'))
          .onPressed,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(notification.requests, 1);
    expect(data.onboardingDone, isTrue);
    await unmount(tester);
  });

  testWidgets('初回起動を済ませた印を保存できなくても、済みにして進む', (tester) async {
    data.failOnboardingSave = true;
    await pumpScreen(tester, data, const NotificationIntroScreen());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotificationIntroScreen)),
    );
    expect(container.read(onboardingDoneProvider), isFalse);
    await tester.tap(find.text('いまはしない'));
    await tester.pumpAndSettle();
    expect(container.read(onboardingDoneProvider), isTrue);
    expect(data.onboardingDone, isFalse);
    await unmount(tester);
  });
}
