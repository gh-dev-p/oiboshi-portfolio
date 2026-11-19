import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/login_method.dart';
import '../../../domain/models/user_settings.dart';
import '../../core/view_models/app_language_provider.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/display_mode_provider.dart';
import '../../core/view_models/guard.dart';
import '../../core/view_models/refresh.dart';
import 'settings_providers.dart';

/// 設定に出すもの。読めていない値は null（読めるまでは、行の値を空にする）。
class SettingsState {
  const SettingsState({
    required this.displayMode,
    required this.language,
    required this.notificationsEnabled,
    required this.ownedCreator,
    required this.loginMethods,
    this.ownedCreatorLoaded = true,
    this.loginMethodsFailed = false,
    this.sessionAnonymous = true,
    this.hiddenCreatorCount,
    this.query = '',
  });

  /// 画面モード。
  final DisplayMode displayMode;

  /// 表示言語。
  final AppLanguage language;

  /// 配信開始の通知の、全体のスイッチ。読めていなければ null。
  final bool? notificationsEnabled;

  /// 自分がオーナーの発信者。発信者でないか、読めていなければ null。
  final Creator? ownedCreator;

  /// 自分の発信者を読めたか（発信者でないと分かったときも true）。読めるまでは、「発信者向け」を出さない。
  final bool ownedCreatorLoaded;

  /// 結び付いたログイン方法。読めていなければ null。
  final List<LoginMethod>? loginMethods;

  /// ログイン方法を読めなかった（読み直している間は false）。
  final bool loginMethodsFailed;

  /// 端末のセッションのユーザーが匿名か。
  final bool sessionAnonymous;

  /// 表示しない発信者の人数。読めていなければ null。
  final int? hiddenCreatorCount;

  /// 検索の言葉。
  final String query;

  /// 匿名のユーザーか。ログイン方法を読めるまで（読めないときも）は、端末のセッションのユーザーで決める
  /// （画面定義書（設定）2.1.1）。
  bool get anonymous => loginMethods?.isEmpty ?? sessionAnonymous;

  /// 検索している（言葉が空でない）か。
  bool get searching => query.trim().isNotEmpty;

  /// [label]（行の名前）が、検索の言葉に合うか。英語は大文字・小文字を区別しない。
  bool matches(String label) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || label.toLowerCase().contains(q);
  }

  SettingsState copyWith({String? query}) => SettingsState(
    displayMode: displayMode,
    language: language,
    notificationsEnabled: notificationsEnabled,
    ownedCreator: ownedCreator,
    loginMethods: loginMethods,
    ownedCreatorLoaded: ownedCreatorLoaded,
    loginMethodsFailed: loginMethodsFailed,
    sessionAnonymous: sessionAnonymous,
    hiddenCreatorCount: hiddenCreatorCount,
    query: query ?? this.query,
  );
}

/// 設定（画面定義書 2.1.1）。アプリ全体の状態（画面モード・表示言語）と、通知の設定・自分の発信者・
/// ログイン方法を1つの state に写し、検索の言葉を持つ。
class SettingsViewModel extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    final owned = ref.watch(ownedCreatorProvider);
    final loginMethods = ref.watch(loginMethodsProvider);
    return SettingsState(
      displayMode: ref.watch(displayModeProvider),
      language: ref.watch(appLanguageProvider),
      notificationsEnabled: ref
          .watch(userSettingsProvider)
          .value
          ?.notificationsEnabled,
      ownedCreator: owned.value,
      ownedCreatorLoaded: owned.hasValue,
      loginMethods: loginMethods.value,
      loginMethodsFailed: loginMethods.hasError && !loginMethods.isLoading,
      // ログイン方法の読み直し（結び付け・ユーザーの切り替わり）のたびに作り直すので、そのときの値を読む。
      sessionAnonymous: ref.read(authRepositoryProvider).isAnonymous,
      hiddenCreatorCount: ref.watch(hiddenCreatorsProvider).value?.length,
      // 読み直しても、検索の言葉は残す。
      query: stateOrNull?.query ?? '',
    );
  }

  /// 読めなかったログイン方法を、読み直す。
  void retryLoginMethods() =>
      reloadFrom(ref, [authSessionProvider, loginMethodsProvider]);

  /// 検索の言葉を変える。
  void setQuery(String query) => state = state.copyWith(query: query);

  /// 画面モードを変える。
  Future<void> setDisplayMode(DisplayMode mode) =>
      ref.read(displayModeProvider.notifier).set(mode);

  /// 表示言語を変える。
  Future<void> setLanguage(AppLanguage language) =>
      ref.read(appLanguageProvider.notifier).set(language);

  /// ログアウトして、新しい匿名のユーザーで始め直す。失敗したら false。
  /// ログアウトの前に、いまのユーザーから、通知の送り先を消す（機能仕様書 4.3.3）。
  /// 新しい匿名のユーザーでのサインインは、作り直した `authSessionProvider` が行う。
  /// できなければ、各画面が「読み込めない」を出し、「もう一度試す」でサインインし直す。
  Future<bool> signOut() async {
    await unregisterDeviceQuietly(ref);
    final ok = await succeeded(() async {
      await ref.read(authRepositoryProvider).signOut();
      resetAfterUserChange(ref);
    });
    if (!ok) registerDeviceAgain(ref);
    return ok;
  }

  /// お問い合わせの下書き。本文に、ユーザー ID・アプリのバージョン・OS を入れる。
  /// 文言は View から受け取る：[subject]（件名）、[body]（本文を作る関数）、
  /// [notSignedIn]（ユーザー ID がないときに入れる文）。
  Future<ContactDraft> contactDraft({
    required String subject,
    required String Function(String userId, String version, String os) body,
    required String notSignedIn,
  }) => buildContactDraft(
    ref,
    subject: subject,
    body: body,
    notSignedIn: notSignedIn,
  );

  /// いまのユーザー ID。サインインしていなければ null。
  String? get userId => currentUserId(ref);
}

final settingsViewModelProvider =
    NotifierProvider.autoDispose<SettingsViewModel, SettingsState>(
      SettingsViewModel.new,
    );
