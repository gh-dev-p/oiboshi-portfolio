import 'dart:async';

import 'package:oiboshi/data/repositories/auth/auth_repository.dart';
import 'package:oiboshi/domain/models/app_error.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/domain/models/user_settings.dart';

import 'fake_data.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this.data);

  final FakeData data;
  bool withdrawn = false;
  String? _appleCode;

  /// サインインしているか。ログアウト・退会で外れ、次の [ensureSignedIn] で、新しい匿名のユーザーになる。
  bool _signedIn = true;
  var _anonymous = 0;

  @override
  String? get userId => data.userId;

  @override
  Stream<String?> get userIdChanges => data.sessionUserChanges.stream;

  @override
  Future<String> ensureSignedIn() async {
    await data.signInGate?.future;
    data.check();
    if (_signedIn) return data.userId ?? 'user-a';
    final next = 'anon-${++_anonymous}';
    data.userId = next;
    _signedIn = true;
    return next;
  }

  @override
  bool get isAnonymous => data.loginMethods.isEmpty;

  @override
  Future<List<LoginMethod>> fetchLoginMethods() async {
    if (data.failLoginMethods) {
      throw const AppException(AppErrorKind.network);
    }
    return [...data.loginMethods];
  }

  @override
  Future<LoginResult> linkLogin(LoginProvider provider) async {
    if (data.loginResult == LoginResult.done) {
      data.loginMethods.add(
        LoginMethod(
          provider: provider,
          identityId: provider.name,
          accountLabel: '${provider.name}@example.com',
        ),
      );
    }
    return data.loginResult;
  }

  @override
  Future<LoginResult> signIn(LoginProvider provider) async {
    data.signInProviders.add(provider);
    final result = data.signInResult ?? data.loginResult;
    if (result == LoginResult.done) {
      data
        ..userId = 'user-${provider.name}'
        ..follows.clear()
        ..follows.addAll(data.signInFollows)
        ..hiddenCreatorIds.clear()
        ..hiddenCreatorIds.addAll(data.signInHiddenCreatorIds)
        ..loginMethods.clear()
        ..loginMethods.add(
          LoginMethod(
            provider: provider,
            identityId: provider.name,
            accountLabel: '${provider.name}@example.com',
          ),
        );
    }
    return result;
  }

  @override
  bool passwordLoginLockedAt(DateTime now) =>
      data.passwordLoginLock.lockedAt(now);

  /// 本物と同じく、端末の回数の制限（[PasswordLoginLock]）を数える。
  @override
  Future<PasswordLoginResult> signInWithPassword(
    String email,
    String password, {
    required DateTime now,
  }) async {
    final lock = data.passwordLoginLock;
    if (lock.lockedAt(now)) return PasswordLoginResult.tooManyAttempts;
    if (data.passwordServerRateLimited) {
      return PasswordLoginResult.tooManyAttempts;
    }
    if (data.passwordAccounts[email] != password) {
      data.passwordLoginLock = lock.failedAt(now);
      return data.passwordLoginLock.lockedAt(now)
          ? PasswordLoginResult.tooManyAttempts
          : PasswordLoginResult.invalidCredentials;
    }
    data
      ..passwordLoginLock = const PasswordLoginLock()
      ..userId = 'user-admin'
      ..follows.clear()
      ..follows.addAll(data.signInFollows)
      ..hiddenCreatorIds.clear()
      ..hiddenCreatorIds.addAll(data.signInHiddenCreatorIds)
      ..loginMethods.clear()
      ..loginMethods.add(
        const LoginMethod(
          provider: LoginProvider.twitch,
          identityId: 'twitch',
          accountLabel: 'reviewer',
        ),
      );
    return PasswordLoginResult.done;
  }

  @override
  Future<String> startAccountMerge() async {
    if (data.startMergeFails) throw const AppException(AppErrorKind.network);
    final token = 'merge-${data.mergeTokens.length + 1}';
    data.mergeTokens.add(token);
    data.mergeSources[token] = ([...data.follows], [...data.hiddenCreatorIds]);
    return token;
  }

  /// 本物（`finish_account_merge`）と同じく、ログイン先の状態を優先して足し合わせる。
  @override
  Future<void> finishAccountMerge(String token) async {
    data.finishedMergeTokens.add(token);
    final source = data.mergeSources.remove(token);
    if (source == null) return;
    final (follows, hidden) = source;
    final followed = data.follows.map((f) => f.creatorId).toSet();
    for (final id in hidden) {
      if (!followed.contains(id) && !data.hiddenCreatorIds.contains(id)) {
        data.hiddenCreatorIds.add(id);
      }
    }
    for (final f in follows) {
      if (!followed.contains(f.creatorId) &&
          !data.hiddenCreatorIds.contains(f.creatorId)) {
        data.follows.add(f);
      }
    }
  }

  @override
  Future<LoginResult> reauthenticate(LoginMethod method) async {
    data.reauthCount++;
    data.reauthProviders.add(method.provider);
    _appleCode =
        method.provider == LoginProvider.apple &&
            data.reauthResult == LoginResult.done
        ? 'apple-code'
        : null;
    return data.reauthResult;
  }

  @override
  Future<void> unlinkLogin(LoginMethod method) async {
    // 本物と同じく、一覧に無ければ失敗にする。
    if (!data.loginMethods.any((m) => m.identityId == method.identityId)) {
      throw const AppException(AppErrorKind.notFound);
    }
    data.loginMethods.removeWhere((m) => m.identityId == method.identityId);
  }

  @override
  Future<void> signOut() async {
    data.loginMethods.clear();
    _signedIn = false;
  }

  @override
  Future<void> withdraw() async {
    if (data.withdrawFails) throw Exception('network');
    withdrawn = true;
    data.revokedAppleCode = _appleCode;
    _appleCode = null;
    data
      ..follows.clear()
      ..loginMethods.clear()
      // 端末内の保存を消す。
      ..onboardingDone = false
      ..displayMode = DisplayMode.system
      ..appLanguage = AppLanguage.system
      ..fixedViewerUserOff = false;
    _signedIn = false;
  }
}
