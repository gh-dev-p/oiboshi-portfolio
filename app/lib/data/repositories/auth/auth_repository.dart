import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/login_method.dart';
import '../../services/auth/auth_service.dart';
import '../../services/settings/app_preferences_store.dart';
import '../common/error_mapping.dart';

/// 匿名のサインイン、ログイン方法（機能仕様書 4.1.4）、退会。
class AuthRepository {
  AuthRepository(this._auth, this._prefs);

  final AuthService _auth;
  final AppPreferencesStore _prefs;

  /// 最後の再認証で、Apple から受け取った一時的なコード。退会のときに、Apple のひも付けの取り消しに使う
  /// （機能仕様書 4.1.3）。使い捨てで、5分で切れる。
  String? _appleCode;

  String? get userId => _auth.userId;

  /// 端末のセッションのユーザー ID の移り変わり。同じ ID が続くときは流さない。セッションがなければ null。
  Stream<String?> get userIdChanges => _auth.userIdChanges.distinct();

  /// 匿名のユーザーか（ログイン方法が1つもない）。
  bool get isAnonymous => _auth.isAnonymous;

  /// 結び付いたログイン方法。匿名のサインインと、知らないサービスは入らない。
  Future<List<LoginMethod>> fetchLoginMethods() => _map(() async {
    final identities = await _auth.identities();
    return [
      for (final i in identities)
        if (LoginProvider.fromName(i.provider) case final provider?)
          LoginMethod(
            provider: provider,
            identityId: i.identityId,
            accountLabel: _accountLabel(i.identityData),
          ),
    ];
  });

  static String? _accountLabel(Map<String, dynamic>? data) {
    for (final key in ['email', 'user_name', 'preferred_username', 'name']) {
      final value = data?[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  /// いまのユーザーに、ログインを結び付ける。匿名なら、匿名ではなくなる（ユーザー ID は変わらない）。
  Future<LoginResult> linkLogin(LoginProvider provider) =>
      _oauth(() => _auth.linkIdentity(provider.name));

  /// 結び付けたログインで入る。いまのユーザーから、そのユーザーに切り替わる。
  Future<LoginResult> signIn(LoginProvider provider) =>
      _oauth(() => _auth.signInWithOAuth(provider.name));

  /// アプリ運営用ログインで、[now] に、この端末が入れないあいだか（[PasswordLoginLock]）。
  bool passwordLoginLockedAt(DateTime now) =>
      _prefs.passwordLoginLock.lockedAt(now);

  /// アプリ運営用ログイン（機能仕様書 4.1.4）。メールアドレスとパスワードで入る。いまのユーザーから切り替わる。
  /// 違ったら、端末の回数の制限（[PasswordLoginLock]）に数え、入れたら数え直す。
  Future<PasswordLoginResult> signInWithPassword(
    String email,
    String password, {
    required DateTime now,
  }) async {
    final lock = _prefs.passwordLoginLock;
    if (lock.lockedAt(now)) return PasswordLoginResult.tooManyAttempts;
    try {
      await _auth.signInWithPassword(email, password);
    } on AuthRetryableFetchException {
      return PasswordLoginResult.failed;
    } on AuthException catch (e) {
      if (e.code == 'invalid_credentials') {
        final next = lock.failedAt(now);
        await _prefs.setPasswordLoginLock(next);
        return next.lockedAt(now)
            ? PasswordLoginResult.tooManyAttempts
            : PasswordLoginResult.invalidCredentials;
      }
      // サーバーの回数の制限（429）。
      if (e.statusCode == '429' || (e.code?.contains('rate_limit') ?? false)) {
        return PasswordLoginResult.tooManyAttempts;
      }
      return PasswordLoginResult.failed;
    } catch (_) {
      return PasswordLoginResult.failed;
    }
    await _prefs.setPasswordLoginLock(const PasswordLoginLock());
    return PasswordLoginResult.done;
  }

  /// 匿名のユーザーが、ログインで切り替わる前に、フォローの足し合わせの券を受け取る（機能仕様書 4.1.4）。
  Future<String> startAccountMerge() => _map(_auth.startAccountMerge);

  /// ログイン先のユーザーが、券で、匿名のユーザーのフォローと表示しない発信者を移す（機能仕様書 4.1.4）。
  Future<void> finishAccountMerge(String token) =>
      _map(() => _auth.finishAccountMerge(token));

  /// 再認証（機能仕様書 4.1.4.1）。結び付けた [method] でもう一度ログインし、いまのユーザーかを確かめる。
  /// アプリのセッションは変えない。Apple なら、受け取った一時的なコードを、退会のために覚える。
  Future<LoginResult> reauthenticate(LoginMethod method) async {
    _appleCode = null;
    final uid = _auth.userId;
    if (uid == null) return LoginResult.failed;
    final result = await _oauth(() async {
      final res = await _auth.reauthenticate(
        method.provider.name,
        queryParams: _reauthParams(method),
      );
      if (res == null) return false;
      if (res.userId != uid) throw const _WrongAccount();
      _appleCode = res.appleAuthorizationCode;
      return true;
    });
    return result;
  }

  /// SNS に、アカウントを選び直す画面を出してもらう指定（tech-risks.md 2.13）。
  static Map<String, String>? _reauthParams(LoginMethod method) =>
      switch (method.provider) {
        LoginProvider.google when method.accountLabel?.contains('@') ?? false =>
          {'login_hint': method.accountLabel!},
        LoginProvider.twitch => {'force_verify': 'true'},
        _ => null,
      };

  /// ログイン方法を外す。最後の1つは、サーバーが断る。
  /// サーバーの一覧に無ければ（ほかの端末で外したなど）、[AppErrorKind.notFound] を投げる（機能仕様書 4.1.4）。
  Future<void> unlinkLogin(LoginMethod method) => _map(() async {
    final identities = await _auth.identities();
    final identity = identities
        .where((i) => i.identityId == method.identityId)
        .firstOrNull;
    if (identity == null) throw const AppException(AppErrorKind.notFound);
    await _auth.unlinkIdentity(identity);
  });

  /// ログアウトする。端末のセッションを消す（機能仕様書 4.1.4）。
  /// 新しい匿名のユーザーでのサインインは、作り直した `authSessionProvider` が [ensureSignedIn] で行う。
  Future<void> signOut() => _map(_signOutLocally);

  /// 端末のセッションを消す。gotrue は、端末のセッションを先に消してから、サーバーに知らせる。
  /// 知らせるのに失敗しても（通信の失敗など）、端末のセッションは消えているので、無視して進める
  /// （サーバー側のセッションは、期限で切れる）。
  Future<void> _signOutLocally() async {
    try {
      await _auth.signOutLocally();
    } catch (_) {
      if (_auth.currentSession != null) rethrow;
    }
  }

  Future<LoginResult> _oauth(Future<bool> Function() action) async {
    try {
      return await action() ? LoginResult.done : LoginResult.cancelled;
    } on _WrongAccount {
      return LoginResult.wrongAccount;
    } on AuthException catch (e) {
      final text = '${e.code} ${e.message}'.toLowerCase();
      if (text.contains('identity_already_exists') ||
          text.contains('already linked') ||
          text.contains('already exists')) {
        return LoginResult.alreadyUsed;
      }
      return LoginResult.failed;
    } catch (_) {
      return LoginResult.failed;
    }
  }

  Future<T> _map<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } on AuthRetryableFetchException catch (e) {
      throw AppException(AppErrorKind.network, e);
    } on AuthException catch (e) {
      throw AppException(AppErrorKind.auth, e);
    } catch (e) {
      throw AppException(AppErrorKind.network, e);
    }
  }

  /// サインイン済みにして、ユーザー ID を返す（機能仕様書 4.1.1.1）。
  /// 前回のセッションが残っていれば、そのまま使う。期限切れなら更新する。サーバーが更新を断ったら
  /// （リフレッシュトークンが無効・サーバー側でユーザーが消えているなど）、捨てて匿名でサインインし直す。
  /// 通信の失敗（gotrue の [AuthRetryableFetchException]）では捨てない。セッションを残して通信のエラーを投げ、
  /// 「もう一度試す」で更新し直す（捨てると、匿名のユーザーのフォローを失うため）。
  Future<String> ensureSignedIn() => _map(() async {
    final session = _auth.currentSession;
    if (session != null) {
      if (!session.isExpired) return _auth.userId!;
      try {
        await _auth.refreshSession();
        return _auth.userId!;
      } on AuthRetryableFetchException {
        rethrow;
      } on AuthException {
        await _signOutLocally();
      }
    }
    await _auth.signInAnonymously();
    return _auth.userId!;
  });

  /// 退会（機能仕様書 4.1.3）。Apple のひも付けの取り消し、カバー画像とユーザー（フォロー・設定・送り先）、
  /// 端末のセッションと端末内の保存の順に消す。
  /// Apple のひも付けは、直前の再認証で Apple のコードを受け取ったときだけ取り消す。取り消せなくても、退会は進める
  /// （取り消せなかったことは、サーバーがログに残す）。取り消しは、ユーザーを消す前に行う（サーバーで本人を確かめるため）。
  /// カバー画像とユーザーは、サーバー（Edge Function `delete-account`）が、まとめて消す。
  /// ユーザーを消せたあとは、サーバーへのログアウトの通知に失敗しても、退会は済んだものとする。
  Future<void> withdraw() async {
    final uid = _auth.userId;
    if (uid == null) throw const AppException(AppErrorKind.auth);
    final appleCode = _appleCode;
    _appleCode = null;
    if (appleCode != null) {
      try {
        await _auth.revokeApple(appleCode);
      } catch (_) {
        // 退会は進める（機能仕様書 4.1.3）。
      }
    }
    await mapErrors(_auth.deleteAccount);
    await _signOutLocally();
    await _prefs.clear();
  }
}

/// 再認証で、違うユーザーにログインした。
class _WrongAccount implements Exception {
  const _WrongAccount();
}
