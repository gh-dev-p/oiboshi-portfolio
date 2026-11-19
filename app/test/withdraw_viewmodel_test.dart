import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';
import 'package:oiboshi/domain/models/user_settings.dart';
import 'package:oiboshi/ui/core/view_models/app_language_provider.dart';
import 'package:oiboshi/ui/core/view_models/auth_session_provider.dart';
import 'package:oiboshi/ui/core/view_models/display_mode_provider.dart';
import 'package:oiboshi/ui/onboarding/view_models/onboarding_providers.dart';
import 'package:oiboshi/ui/settings/view_models/settings_providers.dart';
import 'package:oiboshi/ui/settings/view_models/withdraw_viewmodel.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()
      ..onboardingDone = true
      ..creators.add(sampleCreator());
    container = await testContainer(data);
    // 画面を閉じると破棄する Provider なので、テストの間は監視しておく。
    container.listen(withdrawViewModelProvider, (_, _) {});
  });

  WithdrawState state() => container.read(withdrawViewModelProvider);

  /// 自分の発信者と、ログイン方法を読み終えるまで待つ。
  Future<void> loaded() async {
    await container.read(ownedCreatorProvider.future);
    await container.read(loginMethodsProvider.future);
    await Future<void>.delayed(Duration.zero);
  }

  /// ログイン方法を [methods] にして、読み直す。
  Future<void> setMethods(List<LoginMethod> methods) async {
    data.loginMethods
      ..clear()
      ..addAll(methods);
    container.invalidate(loginMethodsProvider);
    await loaded();
  }

  test('発信者のオーナーかを state に出す', () async {
    await loaded();
    expect(state().ownsCreator, isFalse);

    data.ownedCreatorId = 'minato';
    container.invalidate(ownedCreatorProvider);
    await loaded();
    expect(state().ownsCreator, isTrue);
  });

  test('iOS 以外で Apple を結び付けていれば案内し、Apple だけなら退会できないとする', () async {
    // テストの端末は Android。
    await loaded();
    expect(state().appleElsewhere, isFalse);
    expect(state().appleOnlyElsewhere, isFalse);

    await setMethods([appleLogin, googleLogin]);
    expect(state().appleElsewhere, isTrue);
    expect(state().appleOnlyElsewhere, isFalse);

    await setMethods([appleLogin]);
    expect(state().appleElsewhere, isFalse);
    expect(state().appleOnlyElsewhere, isTrue);
  });

  group('サブスクの解約の案内', () {
    /// サーバーの加入を [subscription] にして、読み直す。
    Future<void> setSubscription(ServerPlanSubscription subscription) async {
      data.serverSubscription = subscription;
      container.invalidate(withdrawViewModelProvider);
      container.listen(withdrawViewModelProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
    }

    final future = DateTime.now().add(const Duration(days: 10));
    final past = DateTime.now().subtract(const Duration(days: 1));

    test('加入したことがなければ、案内を出さない', () async {
      await setSubscription(ServerPlanSubscription.none);
      expect(state().subscriptionNotice, isFalse);
    });

    test('X連携プランの期限が、いまより後なら、案内を出す', () async {
      await setSubscription(ServerPlanSubscription(xOptionExpiresAt: future));
      expect(state().subscriptionNotice, isTrue);
    });

    test('期限が切れていれば、案内を出さない', () async {
      await setSubscription(ServerPlanSubscription(xOptionExpiresAt: past));
      expect(state().subscriptionNotice, isFalse);
    });

    test('加入中かを読み込めないときも、案内を出す', () async {
      data.serverSubscriptionFails = true;
      await setSubscription(ServerPlanSubscription.none);
      expect(state().subscriptionNotice, isTrue);
    });

    test('サブスクの管理は、ストアの管理の画面を開く', () {
      // テストの端末は Android。
      expect(
        container
            .read(withdrawViewModelProvider.notifier)
            .manageSubscriptionsUrl
            .toString(),
        'https://play.google.com/store/account/subscriptions',
      );
    });
  });

  test('iOS では、Apple だけでも退会できる', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await setMethods([appleLogin]);
    expect(state().appleElsewhere, isFalse);
    expect(state().appleOnlyElsewhere, isFalse);
  });

  test('退会すると、初回起動に戻す', () async {
    container.listen(onboardingDoneProvider, (_, _) {});
    expect(container.read(onboardingDoneProvider), isTrue);

    expect(
      await container.read(withdrawViewModelProvider.notifier).withdraw(),
      isTrue,
    );
    expect(data.onboardingDone, isFalse);
    expect(container.read(onboardingDoneProvider), isFalse);
  });

  test('退会すると、画面モード・表示言語を読み直し、前のユーザーの状態を残さない', () async {
    data
      ..displayMode = DisplayMode.dark
      ..appLanguage = AppLanguage.en
      ..loginMethods.add(googleLogin);
    container
      ..listen(displayModeProvider, (_, _) {})
      ..listen(appLanguageProvider, (_, _) {});
    await loaded();
    expect(await container.read(authSessionProvider.future), 'user-a');
    await container.read(reauthProvider.notifier).reauthenticate(googleLogin);
    expect(container.read(reauthProvider), isNotNull);
    expect(container.read(displayModeProvider), DisplayMode.dark);

    expect(
      await container.read(withdrawViewModelProvider.notifier).withdraw(),
      isTrue,
    );
    expect(container.read(displayModeProvider), DisplayMode.system);
    expect(container.read(appLanguageProvider), AppLanguage.system);
    expect(container.read(reauthProvider), isNull);
    // 消したユーザーの ID は残さず、新しい匿名のユーザーでサインインし直す。
    expect(await container.read(authSessionProvider.future), 'anon-1');
    expect(await container.read(loginMethodsProvider.future), isEmpty);
  });

  test('退会に失敗したら false を返し、初回起動には戻さない', () async {
    container.listen(onboardingDoneProvider, (_, _) {});
    data.withdrawFails = true;
    expect(
      await container.read(withdrawViewModelProvider.notifier).withdraw(),
      isFalse,
    );
    expect(container.read(onboardingDoneProvider), isTrue);
  });
}
