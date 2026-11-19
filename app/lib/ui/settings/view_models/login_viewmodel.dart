import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/login_method.dart';
import '../../core/view_models/clock_provider.dart';
import 'settings_providers.dart';

/// アカウント作成／ログイン（シート）の結果（機能仕様書 4.1.4）。
enum LoginOutcome {
  /// 初めてのアカウントだったので、いまのユーザーに結び付けた（アカウント作成。ユーザー ID はそのまま）。
  created,

  /// 使ったことのあるアカウントだったので、そのユーザーに入った（ログイン）。匿名のあいだのフォローは足し合わせた。
  loggedIn,

  /// SNS の画面で閉じた。
  cancelled,

  /// アプリ運営用ログインで、メールアドレスかパスワードが違う。
  invalidCredentials,

  /// アプリ運営用ログインで、入れないあいだ（端末の5分、またはサーバーの回数の制限）。
  tooManyAttempts,
  failed,
}

/// アカウント作成／ログイン（シート）（画面定義書 2.1.6）。まず、いまの匿名のユーザーに結び付け、そのアカウントが
/// ほかのユーザーに結び付いていたら、そのユーザーに入って、フォローを足し合わせる（機能仕様書 4.1.4）。
/// シートを閉じたあとも、ユーザーの切り替えを終えられるように、autoDispose にしない。
class LoginViewModel extends Notifier<void> {
  @override
  void build() {}

  /// [provider] で、アカウントを作るか、ログインする。
  Future<LoginOutcome> continueWith(LoginProvider provider) async {
    switch (await linkLogin(ref, provider)) {
      case LoginResult.done:
        return LoginOutcome.created;
      case LoginResult.cancelled:
        return LoginOutcome.cancelled;
      case LoginResult.failed:
      case LoginResult.wrongAccount:
        return LoginOutcome.failed;
      case LoginResult.alreadyUsed:
        return _logIn(provider);
    }
  }

  /// アプリ運営用ログイン（メールアドレスとパスワード。機能仕様書 4.1.4）。入れたら、使ったことのあるアカウントへの
  /// ログインと同じく、フォローを足し合わせる。端末が入れないあいだなら、何もせずに [LoginOutcome.tooManyAttempts]。
  Future<LoginOutcome> logInWithPassword(String email, String password) {
    final auth = ref.read(authRepositoryProvider);
    final now = ref.read(clockProvider)();
    if (auth.passwordLoginLockedAt(now)) {
      return Future.value(LoginOutcome.tooManyAttempts);
    }
    return _switchUser(() async {
      final result = await auth.signInWithPassword(
        email.trim(),
        password,
        now: now,
      );
      return switch (result) {
        PasswordLoginResult.done => LoginOutcome.loggedIn,
        PasswordLoginResult.invalidCredentials =>
          LoginOutcome.invalidCredentials,
        PasswordLoginResult.tooManyAttempts => LoginOutcome.tooManyAttempts,
        PasswordLoginResult.failed => LoginOutcome.failed,
      };
    });
  }

  /// 使ったことのあるアカウントで入る。
  Future<LoginOutcome> _logIn(LoginProvider provider) => _switchUser(() async {
    final result = await ref.read(authRepositoryProvider).signIn(provider);
    return switch (result) {
      LoginResult.done => LoginOutcome.loggedIn,
      LoginResult.cancelled => LoginOutcome.cancelled,
      _ => LoginOutcome.failed,
    };
  });

  /// ほかのユーザーに入る（[signIn] が [LoginOutcome.loggedIn] を返したら、入れた）。切り替える前に、足し合わせの券を
  /// 受け取り、通知の送り先の登録を消す（機能仕様書 4.3.3）。入れたら、券でフォローを移し、ユーザーが切り替わったので
  /// 読み直す。入れなかったら、登録し直す。
  Future<LoginOutcome> _switchUser(
    Future<LoginOutcome> Function() signIn,
  ) async {
    final auth = ref.read(authRepositoryProvider);
    final String token;
    try {
      token = await auth.startAccountMerge();
    } catch (_) {
      return LoginOutcome.failed;
    }
    await unregisterDeviceQuietly(ref);
    final outcome = await signIn();
    if (outcome != LoginOutcome.loggedIn) {
      registerDeviceAgain(ref);
      return outcome;
    }
    try {
      await auth.finishAccountMerge(token);
    } catch (_) {
      // 移せなくても、ログインは済んだものとする（機能仕様書 4.1.4）。
    }
    resetAfterUserChange(ref);
    return LoginOutcome.loggedIn;
  }
}

final loginViewModelProvider = NotifierProvider<LoginViewModel, void>(
  LoginViewModel.new,
);
