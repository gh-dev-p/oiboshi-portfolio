import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/provider_retry.dart';
import 'package:oiboshi/config/service_providers.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/ui/settings/view_models/settings_providers.dart';

import 'fakes.dart';
import 'package:oiboshi/ui/core/view_models/clock_provider.dart';

void main() {
  late FakeData data;
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    data = FakeData();
    now = DateTime(2026, 10, 19, 12);
    container = ProviderContainer(
      retry: noProviderRetry,
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(data)),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
  });

  ReauthNotifier vm() => container.read(reauthProvider.notifier);

  test('匿名のユーザー（ログイン方法がない）には、再認証を求めない', () {
    expect(vm().isRequired(const []), isFalse);
    expect(vm().isRequired(const [googleLogin]), isTrue);
  });

  test('済んでから5分は求めず、5分たったら、また求める', () async {
    expect(await vm().reauthenticate(googleLogin), LoginResult.done);
    expect(vm().isRequired(const [googleLogin]), isFalse);
    now = now.add(const Duration(minutes: 4, seconds: 59));
    expect(vm().isRequired(const [googleLogin]), isFalse);
    now = now.add(const Duration(seconds: 1));
    expect(vm().isRequired(const [googleLogin]), isTrue);
  });

  test('済まなかったら覚えず、ユーザーが切り替わったら忘れる', () async {
    data.reauthResult = LoginResult.wrongAccount;
    expect(await vm().reauthenticate(googleLogin), LoginResult.wrongAccount);
    expect(vm().isRequired(const [googleLogin]), isTrue);

    data.reauthResult = LoginResult.done;
    await vm().reauthenticate(googleLogin);
    expect(vm().isRequired(const [googleLogin]), isFalse);
    data.userId = 'user-b';
    expect(vm().isRequired(const [googleLogin]), isTrue);
  });
}
