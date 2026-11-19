import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../core/view_models/app_language_provider.dart';
import '../../core/view_models/auth_session_provider.dart';

/// この端末を、いまのユーザーの、配信開始の通知の送り先として登録する（機能仕様書 4.3.3）。
/// ログイン・ログアウト・ユーザーの切り替え・退会で [authSessionProvider] が作り直されると、これも作り直す。
/// アプリの土台（`app.dart`）が、初回起動が済んでから監視し続ける。端末の通知が許可されていなければ、何もしない。
/// 送り先と一緒に、通知の文言の言語（アプリの表示言語）を登録し、表示言語を変えたら登録し直す（i18n設計書 6.5）。
/// 失敗しても、表示は変えない（次の起動で登録し直す）。
final pushRegistrationProvider = FutureProvider<void>(
  (ref) => withSession(ref, (_) async {
    final repo = ref.watch(notificationRepositoryProvider);
    if (!repo.pushAvailable) return;
    String language() => ref.read(appLanguageProvider).notificationLanguage();
    try {
      if (!await repo.isPermissionGranted()) return;
      // FCM が送り先を変えたら、登録し直す。
      final sub = repo.registrationChanges.listen(
        (fid) => repo
            .saveRegistration(fid, language())
            .catchError((Object e) => debugPrint('通知の送り先を登録し直せない: $e')),
      );
      ref.onDispose(sub.cancel);
      // 表示言語を変えたら、新しい言語で登録し直す。
      ref.listen(
        appLanguageProvider,
        (_, next) => repo
            .updateLanguage(next.notificationLanguage())
            .catchError((Object e) => debugPrint('通知の言語を登録し直せない: $e')),
      );
      await repo.registerDevice(language());
    } catch (e) {
      // 次の起動、または通知設定で許可を確かめ直したときに、登録し直す。表示は変えないが、原因はログに出す。
      debugPrint('通知の送り先を登録できない: $e');
    }
  }),
);
