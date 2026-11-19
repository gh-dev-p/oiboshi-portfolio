import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/domain/models/user_settings.dart';
import 'package:oiboshi/ui/core/view_models/auth_session_provider.dart';
import 'package:oiboshi/ui/settings/view_models/settings_providers.dart';
import 'package:oiboshi/ui/settings/view_models/settings_viewmodel.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  late FakeData data;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()..creators.add(sampleCreator());
    container = await testContainer(data);
  });

  /// 設定を開く。画面を閉じると破棄する Provider なので、テストの間は監視しておく。
  void open() => container.listen(settingsViewModelProvider, (_, _) {});

  SettingsState state() => container.read(settingsViewModelProvider);
  SettingsViewModel vm() => container.read(settingsViewModelProvider.notifier);

  /// 通知の設定・自分の発信者・ログイン方法を読み終えるまで待つ。
  Future<void> loaded() async {
    await container.read(userSettingsProvider.future);
    await container.read(ownedCreatorProvider.future);
    await container.read(loginMethodsProvider.future);
    await Future<void>.delayed(Duration.zero);
  }

  test('アプリ全体の状態と、読み取り用 Provider の値を、1つの state に写す', () async {
    data
      ..displayMode = DisplayMode.dark
      ..appLanguage = AppLanguage.en
      ..settings = const UserSettings(notificationsEnabled: false)
      ..ownedCreatorId = 'minato'
      ..loginMethods.add(googleLogin);
    open();
    // 読めるまでは、値を空にする。匿名かは、端末のセッションのユーザーで決める。
    expect(state().notificationsEnabled, isNull);
    expect(state().ownedCreator, isNull);
    expect(state().ownedCreatorLoaded, isFalse);
    expect(state().loginMethods, isNull);
    expect(state().anonymous, isFalse);

    await loaded();
    final s = state();
    expect(s.displayMode, DisplayMode.dark);
    expect(s.language, AppLanguage.en);
    expect(s.notificationsEnabled, isFalse);
    expect(s.ownedCreator?.id, 'minato');
    expect(s.ownedCreatorLoaded, isTrue);
    expect(s.loginMethods?.single.provider, LoginProvider.google);
    expect(s.anonymous, isFalse);
  });

  test('画面モードと表示言語の変更は、端末内に保存し、state に反映する', () async {
    open();
    await vm().setDisplayMode(DisplayMode.light);
    expect(data.displayMode, DisplayMode.light);
    expect(state().displayMode, DisplayMode.light);

    await vm().setLanguage(AppLanguage.ja);
    expect(data.appLanguage, AppLanguage.ja);
    expect(state().language, AppLanguage.ja);
  });

  test('検索の言葉は、行の名前と大文字・小文字を区別せずに比べ、読み直しても残る', () async {
    open();
    expect(state().searching, isFalse);
    expect(state().matches('通知'), isTrue);

    vm().setQuery(' noti ');
    expect(state().searching, isTrue);
    expect(state().matches('Notifications'), isTrue);
    expect(state().matches('言語'), isFalse);

    // 監視している値が変わって作り直しても、検索の言葉は残る。
    await vm().setDisplayMode(DisplayMode.dark);
    expect(state().query, ' noti ');
    expect(state().displayMode, DisplayMode.dark);
  });

  test('ログアウトすると、匿名に戻る', () async {
    data.loginMethods.add(googleLogin);
    open();
    await loaded();
    expect(state().anonymous, isFalse);

    expect(await vm().signOut(), isTrue);
    await loaded();
    expect(state().anonymous, isTrue);
  });

  test('ログイン方法を読めなくても、ログイン中なら匿名にせず、読み直せる', () async {
    data
      ..loginMethods.add(googleLogin)
      ..failLoginMethods = true;
    open();
    await expectLater(
      container.read(loginMethodsProvider.future),
      throwsA(anything),
    );
    await Future<void>.delayed(Duration.zero);
    expect(state().loginMethods, isNull);
    expect(state().loginMethodsFailed, isTrue);
    // 「ログアウト」を出す。
    expect(state().anonymous, isFalse);

    data.failLoginMethods = false;
    vm().retryLoginMethods();
    expect(state().loginMethodsFailed, isFalse);
    await loaded();
    expect(state().loginMethods?.single.provider, LoginProvider.google);
    expect(state().loginMethodsFailed, isFalse);
  });

  test('ログイン方法を読めず、匿名のユーザーなら、「ログイン」を出す', () async {
    data.failLoginMethods = true;
    open();
    await expectLater(
      container.read(loginMethodsProvider.future),
      throwsA(anything),
    );
    await Future<void>.delayed(Duration.zero);
    expect(state().loginMethodsFailed, isTrue);
    expect(state().anonymous, isTrue);
  });

  test('ログアウトすると、新しい匿名のユーザーに切り替わり、前のユーザーの再認証は残さない', () async {
    data.loginMethods.add(googleLogin);
    open();
    await loaded();
    expect(await container.read(authSessionProvider.future), 'user-a');
    await container.read(reauthProvider.notifier).reauthenticate(googleLogin);
    expect(container.read(reauthProvider), isNotNull);

    expect(await vm().signOut(), isTrue);
    expect(await container.read(authSessionProvider.future), 'anon-1');
    expect(container.read(reauthProvider), isNull);
  });

  test('お問い合わせの下書きに、ユーザー ID・アプリのバージョン・OS を入れる', () async {
    open();
    final draft = await vm().contactDraft(
      subject: '件名',
      body: (userId, version, os) => '$userId / $version / $os',
      notSignedIn: '未サインイン',
    );
    expect(draft.subject, '件名');
    expect(draft.body, 'user-a / 1.0.0 (1) / test');
    expect(draft.mailto.scheme, 'mailto');
  });

  test('お問い合わせの mailto は、件名・本文の空白を %20 にする（+ にしない）', () {
    const draft = ContactDraft(
      to: 'support@example.com',
      subject: 'Inquiry about Oiboshi',
      body: 'a b\nc+d',
    );
    final mailto = draft.mailto.toString();
    expect(
      mailto,
      'mailto:support@example.com?subject=Inquiry%20about%20Oiboshi'
      '&body=a%20b%0Ac%2Bd',
    );
  });

  test('サインインしていなければ、本文のユーザー ID の代わりに、その旨を入れる', () async {
    data.userId = null;
    open();
    final draft = await vm().contactDraft(
      subject: '件名',
      body: (userId, version, os) => userId,
      notSignedIn: '未サインイン',
    );
    expect(draft.body, '未サインイン');
    expect(vm().userId, isNull);
  });
}
