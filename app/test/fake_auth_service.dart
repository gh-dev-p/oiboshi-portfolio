import 'package:oiboshi/data/services/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth と Edge Function の代わり。呼ばれた順を記録する。
class FakeAuthService implements AuthService {
  final calls = <String>[];

  /// 端末のセッション。null ならサインインしていない。
  Session? session = sessionFor('user-a');

  /// 再認証で返す、Apple の一時的なコード。
  String? appleCode = 'apple-code';
  String reauthUserId = 'user-a';
  bool revokeFails = false;

  /// セッションの更新で投げる例外。null なら、更新できる。
  Object? refreshError;

  /// 端末のセッションを消したあと、サーバーに知らせるときに投げる例外（gotrue と同じく、セッションは先に消える）。
  Object? signOutError;

  /// 匿名のサインインで投げる例外。
  Object? signInError;

  /// 退会（Edge Function）で投げる例外。
  Object? deleteError;

  /// アプリ運営用ログインで投げる例外。null なら、入れる（ユーザーは `user-admin` になる）。
  Object? passwordError;

  /// サーバーにある、結び付いたログイン方法。
  final identityList = <UserIdentity>[];

  var _anonymous = 0;

  @override
  Future<List<UserIdentity>> identities() async => [...identityList];

  @override
  Future<void> unlinkIdentity(UserIdentity identity) async {
    calls.add('unlink:${identity.identityId}');
    identityList.removeWhere((i) => i.identityId == identity.identityId);
  }

  /// [userId] のセッション。[expired] なら、期限切れ。
  static Session sessionFor(String userId, {bool expired = false}) => Session(
    accessToken: 'token-$userId',
    tokenType: 'bearer',
    user: User(
      id: userId,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '',
    ),
  )..expiresAt = expired ? 0 : null;

  @override
  Session? get currentSession => session;

  @override
  String? get userId => session?.user.id;

  @override
  Future<void> refreshSession() async {
    calls.add('refresh');
    if (refreshError case final e?) throw e;
    session = sessionFor(userId!);
  }

  @override
  Future<void> signInAnonymously() async {
    calls.add('signIn');
    if (signInError case final e?) throw e;
    session = sessionFor('anon-${++_anonymous}');
  }

  @override
  Future<({String userId, String? appleAuthorizationCode})?> reauthenticate(
    String provider, {
    Map<String, String>? queryParams,
  }) async => (
    userId: reauthUserId,
    appleAuthorizationCode: provider == 'apple' ? appleCode : null,
  );

  @override
  Future<String?> revokeApple(String code) async {
    calls.add('revoke:$code');
    if (revokeFails) throw Exception('network');
    return 'revoked';
  }

  @override
  Future<void> deleteAccount() async {
    calls.add('delete');
    if (deleteError case final e?) throw e;
  }

  @override
  Future<void> signOutLocally() async {
    calls.add('signOut');
    session = null;
    if (signOutError case final e?) throw e;
  }

  @override
  Future<void> signInWithPassword(String email, String password) async {
    calls.add('password');
    if (passwordError case final e?) throw e;
    session = sessionFor('user-admin');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
