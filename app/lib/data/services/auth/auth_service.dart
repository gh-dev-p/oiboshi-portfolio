import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/edge_functions.dart';
import '../common/supabase_names.dart';
import '../common/web_auth.dart';

/// Supabase Auth のラッパー。
class AuthService {
  AuthService(this._client, {required String authUrl}) : _authUrl = authUrl;

  final SupabaseClient _client;

  /// Supabase Auth の URL（`{SUPABASE_URL}/auth/v1`）。再認証の、使い捨てのクライアントに使う。
  final String _authUrl;

  /// SNS のログインのあと、Supabase Auth が戻す先。Supabase の Redirect URLs に入れておく。
  static const _redirectTo = '$appCallbackScheme://auth-callback';

  Session? get currentSession => _client.auth.currentSession;

  String? get userId => _client.auth.currentUser?.id;

  /// 端末のセッションのユーザー ID の移り変わり（サインイン・ログイン・ログアウト・更新のたびに流れる）。
  /// セッションがなければ null。
  Stream<String?> get userIdChanges =>
      _client.auth.onAuthStateChange.map((s) => s.session?.user.id);

  /// 匿名のユーザーか（ログイン方法が1つもない）。
  bool get isAnonymous => _client.auth.currentUser?.isAnonymous ?? true;

  Future<void> signInAnonymously() => _client.auth.signInAnonymously();

  Future<void> refreshSession() => _client.auth.refreshSession();

  Future<void> signOutLocally() =>
      _client.auth.signOut(scope: SignOutScope.local);

  /// 退会（Edge Function `delete-account`）。サーバーが、ファンのカバー画像を消し切ってから、ユーザーを消す。
  Future<void> deleteAccount() =>
      _client.functions.invoke(EdgeFunctions.deleteAccount);

  /// 結び付いたログイン方法（サーバーから読み直す）。
  Future<List<UserIdentity>> identities() => _client.auth.getUserIdentities();

  /// Apple を、iOS の標準のシート（ブラウザを使わない）で扱うか。
  /// この方式は、Supabase の Apple の Secret Key（6か月で切れる）が要らない。
  static bool get usesNativeApple => Platform.isIOS;

  /// いまのユーザーに、[provider] のログインを結び付ける。閉じたら false。
  Future<bool> linkIdentity(String provider) async {
    if (provider == OAuthProvider.apple.name && usesNativeApple) {
      return await _nativeApple(_client.auth, link: true) != null;
    }
    final res = await _client.auth.getLinkIdentityUrl(
      OAuthProvider(provider),
      redirectTo: _redirectTo,
    );
    return _completeOAuth(_client.auth, res.url);
  }

  /// [provider] でログインする（いまのユーザーから切り替わる）。閉じたら false。
  Future<bool> signInWithOAuth(String provider) async {
    if (provider == OAuthProvider.apple.name && usesNativeApple) {
      return await _nativeApple(_client.auth, link: false) != null;
    }
    final res = await _client.auth.getOAuthSignInUrl(
      provider: OAuthProvider(provider),
      redirectTo: _redirectTo,
    );
    return _completeOAuth(_client.auth, res.url);
  }

  /// アプリ運営用ログイン（機能仕様書 4.1.4）。メールアドレスとパスワードで入る（いまのユーザーから切り替わる）。
  Future<void> signInWithPassword(String email, String password) =>
      _client.auth.signInWithPassword(email: email, password: password);

  /// 再認証（機能仕様書 4.1.4.1）。[provider] でもう一度ログインし、ログインできたユーザーの ID を返す。閉じたら null。
  /// Apple（iOS の標準のシート）なら、一時的なコード（authorization code）も返す。退会のときの、Apple のひも付けの
  /// 取り消しに使う（機能仕様書 4.1.3）。Supabase は ID トークンだけを使うので、コードは使われずに残る。
  /// 違うアカウントを選んでも、アプリのセッションが切り替わらないように、使い捨てのクライアントでログインし、
  /// 済んだらそのセッションを消す（tech-risks.md 2.13）。[queryParams] は、SNS の認可の URL に付く。
  Future<({String userId, String? appleAuthorizationCode})?> reauthenticate(
    String provider, {
    Map<String, String>? queryParams,
  }) async {
    final auth = GoTrueClient(
      url: _authUrl,
      headers: _client.auth.headers,
      autoRefreshToken: false,
      asyncStorage: _MemoryAsyncStorage(),
    );
    try {
      final bool ok;
      String? appleCode;
      if (provider == OAuthProvider.apple.name && usesNativeApple) {
        final credential = await _nativeApple(auth, link: false);
        ok = credential != null;
        appleCode = credential?.authorizationCode;
      } else {
        final res = await auth.getOAuthSignInUrl(
          provider: OAuthProvider(provider),
          redirectTo: _redirectTo,
          queryParams: queryParams,
        );
        ok = await _completeOAuth(auth, res.url);
      }
      final id = auth.currentUser?.id;
      return ok && id != null
          ? (userId: id, appleAuthorizationCode: appleCode)
          : null;
    } finally {
      if (auth.currentSession != null) {
        try {
          await auth.signOut();
        } catch (_) {
          // 消せなくても、セッションは期限で切れる。
        }
      }
      auth.dispose();
    }
  }

  /// iOS の標準のシートで Apple の ID トークンをもらい、Supabase に渡す（機能仕様書 4.1.4）。
  /// リプレイを防ぐため、乱数（nonce）を作り、ハッシュを Apple に、元の値を Supabase に渡す。
  /// Apple から受け取った情報を返す。閉じたら null。
  Future<AuthorizationCredentialAppleID?> _nativeApple(
    GoTrueClient auth, {
    required bool link,
  }) async {
    final random = Random.secure();
    final rawNonce = base64Url.encode(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
    final idToken = credential.identityToken;
    if (idToken == null) throw AuthException('Apple の ID トークンがない');
    if (link) {
      await auth.linkIdentityWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } else {
      await auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    }
    return credential;
  }

  /// Apple のひも付けを取り消す（Edge Function `revoke-apple`）。[code] は、再認証で受け取った一時的なコード。
  /// 結果の文字列（`revoked` など）を返す。
  Future<String?> revokeApple(String code) => _client.functions
      .invokeResult<String?>(EdgeFunctions.revokeApple, body: {'code': code});

  /// 匿名のユーザーが、フォローの足し合わせの券を受け取る（関数 `start_account_merge`）。
  Future<String> startAccountMerge() async =>
      await _client.rpc<String>(Functions.startAccountMerge);

  /// ログイン先のユーザーが、券で匿名のユーザーのフォローを移す（関数 `finish_account_merge`）。
  Future<void> finishAccountMerge(String token) => _client.rpc<void>(
    Functions.finishAccountMerge,
    params: {'p_token': token},
  );

  Future<void> unlinkIdentity(UserIdentity identity) =>
      _client.auth.unlinkIdentity(identity);

  /// アプリ内のブラウザで SNS のログインを済ませ、戻ってきたコードをセッションに換える。
  /// 失敗は、戻り先の `error_code`・`error_description` を [AuthException] にして投げる。
  Future<bool> _completeOAuth(GoTrueClient auth, String url) async {
    final callback = await authenticateInBrowser(url);
    if (callback == null) return false;
    final uri = Uri.parse(callback);
    // エラーは、クエリかフラグメントに付く。
    final params = {
      ...Uri.splitQueryString(uri.fragment),
      ...uri.queryParameters,
    };
    final error = params['error'];
    if (error != null) {
      if (error == 'access_denied') return false;
      throw AuthException(
        params['error_description'] ?? error,
        code: params['error_code'] ?? error,
      );
    }
    final code = params['code'];
    if (code == null) throw AuthException('code がない');
    await auth.exchangeCodeForSession(code);
    return true;
  }
}

/// 再認証の、使い捨てのクライアントの保存先（PKCE の値だけを置く）。端末には残さない。
class _MemoryAsyncStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);
}
