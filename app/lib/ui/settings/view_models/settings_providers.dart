import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/login_method.dart';
import '../../../domain/models/user_settings.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/clock_provider.dart';
import '../../notification/view_models/notification_providers.dart';

/// ユーザーごとの通知の設定。
final userSettingsProvider = FutureProvider<UserSettings>(
  (ref) => withSession(
    ref,
    (_) => ref.watch(settingsRepositoryProvider).fetchUserSettings(),
  ),
);

/// 自分がオーナーの発信者。発信者でなければ null。
/// 設定を開くたびに読み直す（運営がオーナーを入れたとき、アプリを起動し直さなくても出るように）。
final ownedCreatorProvider = FutureProvider.autoDispose<Creator?>(
  (ref) => withSession(
    ref,
    (_) => ref.watch(creatorAdminRepositoryProvider).fetchOwnedCreator(),
  ),
);

/// 表示しない発信者（機能仕様書 4.2.6）。表示しないにした順（新しい順）。
/// 停止中などで読めなくなった発信者は、出さない。表示しないにした・戻したときは、`ref.invalidate` で読み直す。
final hiddenCreatorsProvider = FutureProvider.autoDispose<List<Creator>>(
  (ref) => withSession(ref, (_) async {
    final ids = await ref.watch(hiddenCreatorRepositoryProvider).fetchIds();
    return ref.watch(creatorRepositoryProvider).fetchMany(ids);
  }),
);

/// 結び付いたログイン方法（機能仕様書 4.1.4）。空なら、匿名のユーザー。
/// 設定・ログイン方法・ログインのシート・本人の確認・退会・発信者として登録が読む。
/// 結び付けた・外したときは、`ref.invalidate` で読み直す。ユーザーが切り替わると、[authSessionProvider] とともに作り直す。
final loginMethodsProvider = FutureProvider<List<LoginMethod>>(
  (ref) => withSession(
    ref,
    (_) => ref.watch(authRepositoryProvider).fetchLoginMethods(),
  ),
);

/// 再認証（機能仕様書 4.1.4.1）。状態は、最後に済んだユーザーと時刻（済んでいなければ null）。
/// 本人の確認のシートと、退会・ログイン方法などの操作をまたいで使うので、ここに置く。
/// アプリの中だけで覚える。ユーザーが切り替わったら（ログイン・ログアウト）、済んでいないとみなす。
class ReauthNotifier extends Notifier<({String userId, DateTime at})?> {
  /// 済んでから、もう一度は求めない時間。
  static const validFor = Duration(minutes: 5);

  @override
  ({String userId, DateTime at})? build() => null;

  /// いまのユーザーで、5分以内に済んでいるか。
  bool get isFresh {
    final last = state;
    return last != null &&
        last.userId == ref.read(authRepositoryProvider).userId &&
        ref.read(clockProvider)().difference(last.at) < validFor;
  }

  /// [methods]（いまのユーザーのログイン方法）のとき、操作の前に再認証が要るか。
  /// 匿名のユーザー（ログイン方法がない）には求めない。
  bool isRequired(List<LoginMethod> methods) => methods.isNotEmpty && !isFresh;

  /// 結び付けた [method] で、もう一度ログインする。済んだら、ユーザーと時刻を覚える。
  Future<LoginResult> reauthenticate(LoginMethod method) async {
    final auth = ref.read(authRepositoryProvider);
    final result = await auth.reauthenticate(method);
    final uid = auth.userId;
    if (result == LoginResult.done && uid != null) {
      state = (userId: uid, at: ref.read(clockProvider)());
    }
    return result;
  }
}

final reauthProvider =
    NotifierProvider<ReauthNotifier, ({String userId, DateTime at})?>(
      ReauthNotifier.new,
    );

/// いまのユーザーに、ログインを結び付ける。結び付けたら、ログイン方法を読み直す。
/// ログイン方法の画面と、ログインのシートの ViewModel から使う。
Future<LoginResult> linkLogin(Ref ref, LoginProvider provider) async {
  final result = await ref.read(authRepositoryProvider).linkLogin(provider);
  if (result == LoginResult.done) ref.invalidate(loginMethodsProvider);
  return result;
}

/// いまのユーザー ID。サインインしていなければ null。設定と、発信者メニューの ViewModel から使う。
String? currentUserId(Ref ref) => ref.read(authRepositoryProvider).userId;

/// 端末の通知の許可を求める（OS の許可の画面を出す）。失敗しても何もしない。
/// 通知の説明（初回起動）と、通知設定の ViewModel から使う。
Future<void> requestNotificationPermission(Ref ref) async {
  try {
    await ref.read(notificationRepositoryProvider).requestPermission();
  } catch (_) {}
}

/// ユーザーが切り替わった（ログイン・ログアウト）。前のユーザーの状態を残さないように、サインインと再認証を作り直す
/// （依存する Provider も、それで作り直される）。ログインのシートと設定の ViewModel から使う。
void resetAfterUserChange(Ref ref) => ref
  ..invalidate(authSessionProvider)
  ..invalidate(reauthProvider);

/// 切り替えの前に、いまのユーザーから、この端末の通知の送り先を消す（機能仕様書 4.3.3）。
/// 消せなくても、切り替えは進める（切り替えたあとの登録で、新しいユーザーに移る）。
Future<void> unregisterDeviceQuietly(Ref ref) async {
  try {
    await ref.read(notificationRepositoryProvider).unregisterDevice();
  } catch (_) {}
}

/// 切り替えをやめたので、いまのユーザーの送り先を登録し直す。
void registerDeviceAgain(Ref ref) => ref.invalidate(pushRegistrationProvider);

/// お問い合わせのメールの下書き。
class ContactDraft {
  const ContactDraft({
    required this.to,
    required this.subject,
    required this.body,
  });

  final String to;
  final String subject;
  final String body;

  /// 件名・本文は `Uri.encodeComponent` で組み立てる。`queryParameters` だと、空白が `+` になり、
  /// メールアプリによっては、そのまま「+」と出る。
  Uri get mailto => Uri(
    scheme: 'mailto',
    path: to,
    query:
        'subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
  );
}

/// お問い合わせの下書きを作る。本文に、ユーザー ID・アプリのバージョン・OS を入れる。
/// 文言は View から受け取る：[subject]（件名）、[body]（本文を作る関数）、[notSignedIn]（ユーザー ID がないときに入れる文）。
/// 設定と、発信者メニュー（停止中の案内）の ViewModel から使う。
Future<ContactDraft> buildContactDraft(
  Ref ref, {
  required String subject,
  required String Function(String userId, String version, String os) body,
  required String notSignedIn,
}) async {
  final repo = ref.read(settingsRepositoryProvider);
  final userId = ref.read(authRepositoryProvider).userId ?? notSignedIn;
  final version = await repo.appVersion();
  return ContactDraft(
    to: supportEmail,
    subject: subject,
    body: body(userId, version, repo.osName()),
  );
}
