import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'ui/core/themes/app_theme.dart';
import 'ui/core/ui/dev_env_banner.dart';
import 'ui/core/ui/loading_overlay_host.dart';
import 'ui/core/view_models/app_language_provider.dart';
import 'ui/core/view_models/billing_user_provider.dart';
import 'ui/core/view_models/display_mode_provider.dart';
import 'ui/core/view_models/loading_overlay_provider.dart';
import 'ui/home/widgets/home_shell.dart';
import 'ui/notification/view_models/live_notification_viewmodel.dart';
import 'ui/onboarding/view_models/onboarding_providers.dart';
import 'ui/onboarding/widgets/welcome_screen.dart';
import 'ui/share/view_models/share_link_viewmodel.dart';
import 'ui/notification/view_models/notification_providers.dart';

/// MaterialApp（テーマ・全画面共通のラップ）と、起動時の振り分け。
class OiboshiApp extends ConsumerWidget {
  const OiboshiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayMode = ref.watch(displayModeProvider);
    final language = ref.watch(appLanguageProvider);
    // 配信開始の通知は、起動したときから受け、ホームに着くまで残す（初回起動の途中に押した・届いたもの）。
    ref.listen(liveNotificationViewModelProvider, (_, _) {});
    // 共有のリンクも、起動したときから受け、ホームに着くまで残す（届ける・広める仕様書 4.3.3）。
    ref.listen(pendingCreatorLinkProvider, (_, _) {});
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      // 表示言語（i18n設計書 3章）。端末の設定に従うときは null。
      locale: language.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: displayMode.themeMode,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        // dev のアプリでは、全画面の右上に「DEV」の帯を出す（環境構成 10）。
        child: DevEnvBanner(
          child: Consumer(
            builder: (context, ref, _) => LoadingOverlayHost(
              visible: ref.watch(loadingOverlayProvider.select((n) => n > 0)),
              child: child!,
            ),
          ),
        ),
      ),
      home: const _StartGate(),
    );
  }
}

/// 初回起動が済んでいればホーム、済んでいなければウェルカム。
class _StartGate extends ConsumerWidget {
  const _StartGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(onboardingDoneProvider);
    return done ? const _UserSync(child: HomeShell()) : const WelcomeScreen();
  }
}

/// ユーザーの切り替えに合わせて、画面に関係なくそろえ続ける。RevenueCat のユーザー（機能仕様書 4.6.6）と、
/// 配信開始の通知の送り先（機能仕様書 4.3.3）。初回起動が済むまで（規約に同意するまで）は、何もしない。
class _UserSync extends ConsumerWidget {
  const _UserSync({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(billingUserProvider, (_, _) {});
    ref.listen(pushRegistrationProvider, (_, _) {});
    return child;
  }
}
