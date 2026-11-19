import 'enum_name.dart';

/// ログインに使えるサービス（機能仕様書 4.1.4）。ツイキャスと Instagram は、Supabase Auth が対応していないので入らない。
enum LoginProvider {
  apple('Apple'),
  google('Google'),
  x('X'),
  twitch('Twitch');

  const LoginProvider(this.label);

  final String label;

  /// 画面に出すログイン方法。Apple は iOS だけ（iOS の標準のシートで扱う。Android には出さない）。
  static List<LoginProvider> available({required bool isIOS}) => [
    for (final p in values)
      if (p != apple || isIOS) p,
  ];

  /// Supabase Auth のプロバイダー名から引く。知らない名前なら null。
  static LoginProvider? fromName(String? name) => values.byNameOrNull(name);
}

/// ユーザーに結び付いたログイン方法（Supabase Auth の identity）。
class LoginMethod {
  const LoginMethod({
    required this.provider,
    required this.identityId,
    this.accountLabel,
  });

  final LoginProvider provider;

  /// 外すときに使う ID。
  final String identityId;

  /// 画面に出すアカウント（メールアドレスまたはユーザー名）。取れなければ null。
  final String? accountLabel;
}

/// ログイン・結び付けの結果。
enum LoginResult {
  done,

  /// SNS の画面で、許可しなかった・閉じた。
  cancelled,

  /// ほかのユーザーに結び付いたログイン。
  alreadyUsed,

  /// 再認証で、いまのユーザーに結び付いていないアカウントでログインした。
  wrongAccount,
  failed,
}

/// アプリ運営用ログイン（メールアドレスとパスワード。機能仕様書 4.1.4）の結果。
enum PasswordLoginResult {
  done,

  /// メールアドレスかパスワードが違う。
  invalidCredentials,

  /// 入れないあいだ（端末の [PasswordLoginLock]、またはサーバーの回数の制限）。
  tooManyAttempts,
  failed,
}

/// アプリ運営用ログインの、端末の回数の制限（機能仕様書 4.1.4）。
/// [maxFailures] 回続けて、メールアドレスかパスワードが違ったら、[lockFor] のあいだ入れない。
class PasswordLoginLock {
  const PasswordLoginLock({this.failures = 0, this.lockedUntil});

  static const maxFailures = 5;
  static const lockFor = Duration(minutes: 5);

  /// 続けて違った回数（入れないあいだに入ると、0 に戻る）。
  final int failures;

  /// 入れない期限。なければ null。
  final DateTime? lockedUntil;

  /// [now] に、入れないあいだか。
  bool lockedAt(DateTime now) => lockedUntil?.isAfter(now) ?? false;

  /// 違ったあと。[maxFailures] 回目なら、[now] から [lockFor] のあいだ入れなくし、数え直す。
  PasswordLoginLock failedAt(DateTime now) => failures + 1 >= maxFailures
      ? PasswordLoginLock(lockedUntil: now.add(lockFor))
      : PasswordLoginLock(failures: failures + 1, lockedUntil: lockedUntil);
}
