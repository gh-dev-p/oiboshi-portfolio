import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/data/repositories/auth/auth_repository.dart';
import 'package:oiboshi/data/services/settings/app_preferences_store.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fake_auth_service.dart';

void main() {
  late FakeAuthService auth;
  late SharedPreferences prefs;
  late AuthRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'onboardingDone': true,
      'displayMode': 'dark',
    });
    prefs = await SharedPreferences.getInstance();
    auth = FakeAuthService();
    repo = AuthRepository(auth, AppPreferencesStore(prefs));
  });

  Matcher throwsAppError(AppErrorKind kind) =>
      throwsA(isA<AppException>().having((e) => e.kind, 'kind', kind));

  group('起動時のサインイン（機能仕様書 4.1.1.1）', () {
    test('期限内のセッションは、そのまま使う', () async {
      expect(await repo.ensureSignedIn(), 'user-a');
      expect(auth.calls, isEmpty);
    });

    test('期限切れのセッションは、更新して使う', () async {
      auth.session = FakeAuthService.sessionFor('user-a', expired: true);
      expect(await repo.ensureSignedIn(), 'user-a');
      expect(auth.calls, ['refresh']);
    });

    test('通信の失敗で更新できなければ、セッションを残して、通信のエラーを投げる', () async {
      auth
        ..session = FakeAuthService.sessionFor('user-a', expired: true)
        ..refreshError = AuthRetryableFetchException(message: 'offline');
      await expectLater(
        repo.ensureSignedIn(),
        throwsAppError(AppErrorKind.network),
      );
      expect(auth.calls, ['refresh']);
      expect(auth.userId, 'user-a');

      // 「もう一度試す」で、同じユーザーのまま更新し直す。
      auth.refreshError = null;
      expect(await repo.ensureSignedIn(), 'user-a');
    });

    test('サーバーが更新を断ったら、セッションを捨てて、匿名でサインインし直す', () async {
      auth
        ..session = FakeAuthService.sessionFor('user-a', expired: true)
        ..refreshError = const AuthApiException(
          'Invalid Refresh Token',
          statusCode: '400',
          code: 'refresh_token_not_found',
        );
      expect(await repo.ensureSignedIn(), 'anon-1');
      expect(auth.calls, ['refresh', 'signOut', 'signIn']);
    });

    test('セッションがなければ、匿名でサインインする。通信の失敗は、通信のエラー', () async {
      auth
        ..session = null
        ..signInError = AuthRetryableFetchException(message: 'offline');
      await expectLater(
        repo.ensureSignedIn(),
        throwsAppError(AppErrorKind.network),
      );
      auth.signInError = null;
      expect(await repo.ensureSignedIn(), 'anon-1');
    });
  });

  group('ログイン方法を外す（機能仕様書 4.1.4）', () {
    UserIdentity identity(String id) => UserIdentity(
      id: id,
      userId: 'user-a',
      identityData: const {},
      identityId: id,
      provider: 'google',
      createdAt: '',
      lastSignInAt: '',
    );
    const method = LoginMethod(
      provider: LoginProvider.google,
      identityId: 'google-1',
    );

    test('サーバーの一覧にあれば、外す', () async {
      auth.identityList.add(identity('google-1'));
      await repo.unlinkLogin(method);
      expect(auth.calls, ['unlink:google-1']);
    });

    test('サーバーの一覧に無ければ、外したことにせず、失敗にする', () async {
      auth.identityList.add(identity('twitch-1'));
      await expectLater(
        repo.unlinkLogin(method),
        throwsAppError(AppErrorKind.notFound),
      );
      expect(auth.calls, isEmpty);
    });
  });

  group('ログアウト（機能仕様書 4.1.4）', () {
    test('サーバーに知らせるのに失敗しても、端末のセッションを消して済ませる', () async {
      auth.signOutError = AuthRetryableFetchException(message: 'offline');
      await repo.signOut();
      expect(auth.currentSession, isNull);
      // 新しい匿名のユーザーは、作り直した authSessionProvider が作る。
      expect(await repo.ensureSignedIn(), 'anon-1');
    });
  });

  group('退会（機能仕様書 4.1.3）', () {
    test('ユーザーを消してから、端末のセッションと、端末内の保存を消す', () async {
      await repo.withdraw();
      expect(auth.calls, ['delete', 'signOut']);
      expect(auth.currentSession, isNull);
      expect(prefs.getKeys(), isEmpty);
    });

    test('ユーザーを消せたあとは、サーバーへのログアウトの通知に失敗しても、退会を済ませる', () async {
      auth.signOutError = AuthRetryableFetchException(message: 'offline');
      await repo.withdraw();
      expect(auth.currentSession, isNull);
      expect(prefs.getKeys(), isEmpty);
    });

    test('ユーザーを消せなければ、失敗にして、セッションも端末内の保存も残す', () async {
      auth.deleteError = Exception('network');
      await expectLater(repo.withdraw(), throwsAppError(AppErrorKind.network));
      expect(auth.calls, ['delete']);
      expect(auth.userId, 'user-a');
      expect(prefs.getBool('onboardingDone'), isTrue);
    });

    test('退会の関数の失敗は unknown、届かなければ network', () async {
      auth.deleteError = const FunctionsHttpException(status: 500);
      await expectLater(repo.withdraw(), throwsAppError(AppErrorKind.unknown));
      auth.deleteError = const FunctionsFetchException(details: 'offline');
      await expectLater(repo.withdraw(), throwsAppError(AppErrorKind.network));
    });
  });

  group('アプリ運営用ログイン（機能仕様書 4.1.4）', () {
    final now = DateTime.utc(2026, 11, 11, 12);
    const wrong = AuthApiException(
      'Invalid login credentials',
      statusCode: '400',
      code: 'invalid_credentials',
    );

    test('入れたら、ユーザーが切り替わり、違った回数を数え直す', () async {
      auth.passwordError = wrong;
      expect(
        await repo.signInWithPassword('a@example.com', 'x', now: now),
        PasswordLoginResult.invalidCredentials,
      );
      auth.passwordError = null;
      expect(
        await repo.signInWithPassword('a@example.com', 'y', now: now),
        PasswordLoginResult.done,
      );
      expect(auth.userId, 'user-admin');
      expect(prefs.getInt('passwordLoginFailures'), 0);
    });

    test('5回続けて違ったら、5分のあいだ入れない（サーバーに問い合わせない）。過ぎたら入れる', () async {
      auth.passwordError = wrong;
      for (var i = 0; i < 4; i++) {
        expect(
          await repo.signInWithPassword('a@example.com', 'x', now: now),
          PasswordLoginResult.invalidCredentials,
        );
      }
      expect(
        await repo.signInWithPassword('a@example.com', 'x', now: now),
        PasswordLoginResult.tooManyAttempts,
      );
      expect(auth.calls.where((c) => c == 'password'), hasLength(5));
      auth.passwordError = null;
      final later = now.add(const Duration(minutes: 4, seconds: 59));
      expect(repo.passwordLoginLockedAt(later), isTrue);
      expect(
        await repo.signInWithPassword('a@example.com', 'y', now: later),
        PasswordLoginResult.tooManyAttempts,
      );
      expect(auth.calls.where((c) => c == 'password'), hasLength(5));
      // 端末に残るので、作り直しても入れない。
      final again = AuthRepository(auth, AppPreferencesStore(prefs));
      expect(again.passwordLoginLockedAt(later), isTrue);
      final after = now.add(const Duration(minutes: 5));
      expect(repo.passwordLoginLockedAt(after), isFalse);
      expect(
        await repo.signInWithPassword('a@example.com', 'y', now: after),
        PasswordLoginResult.done,
      );
    });

    test('サーバーの回数の制限は、しばらく待つように知らせる。通信の失敗は、回数に数えない', () async {
      auth.passwordError = const AuthApiException(
        'Request rate limit reached',
        statusCode: '429',
        code: 'over_request_rate_limit',
      );
      expect(
        await repo.signInWithPassword('a@example.com', 'x', now: now),
        PasswordLoginResult.tooManyAttempts,
      );
      auth.passwordError = AuthRetryableFetchException(message: 'offline');
      expect(
        await repo.signInWithPassword('a@example.com', 'x', now: now),
        PasswordLoginResult.failed,
      );
      expect(prefs.getInt('passwordLoginFailures'), isNull);
    });
  });
}
