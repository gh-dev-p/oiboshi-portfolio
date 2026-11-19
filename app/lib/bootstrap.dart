import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/app_env.dart';
import 'config/app_flavor.dart';
import 'config/preferences_provider.dart';
import 'config/provider_retry.dart';
import 'data/services/auth/secure_session_storage.dart';
import 'l10n/app_localizations.dart';
import 'ui/core/ui/dev_env_banner.dart';

/// 起動処理（アーキテクチャ設計書 6.2）。Supabase と Firebase（FCM）を初期化し、`ProviderScope` でアプリを起動する。
/// 端末の保存（SharedPreferences）と Supabase の初期化に失敗したとき（10秒で終わらないときも）は、白い画面にせず、
/// エラーの内容を出す。
/// Firebase は、接続の値がないときと、初期化に失敗したときは、通知だけを止めて起動する。
/// [flavor] と接続先が食い違うとき（dev のアプリから本番へなど）は、つながずにエラーを出す（環境構成 10）。
Future<void> bootstrap(AppFlavor flavor) async {
  AppFlavor.current = flavor;
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError = flavorMismatch(flavor, AppEnv.supabaseUrl);
  SharedPreferences? preferences;
  if (startupError == null) {
    try {
      preferences = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 10),
      );
      await Supabase.initialize(
        url: AppEnv.supabaseUrl,
        publishableKey: AppEnv.supabaseKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureSessionStorage(
            persistSessionKey: SecureSessionStorage.keyFor(AppEnv.supabaseUrl),
          ),
          // SNS のログインは、アプリ内のブラウザから戻ったコードを自分で換える（AuthService）。
          detectSessionInUri: false,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      startupError = e;
    }
  }
  final firebaseOptions = AppEnv.firebaseOptions;
  if (startupError == null && firebaseOptions != null) {
    try {
      await Firebase.initializeApp(options: firebaseOptions)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Firebase を初期化できない（通知は届かない）: $e');
    }
  }
  runApp(
    ProviderScope(
      retry: noProviderRetry,
      overrides: [
        if (preferences != null)
          sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: startupError == null
          ? const OiboshiApp()
          : DevEnvBanner(child: StartupErrorApp(error: startupError)),
    ),
  );
}

/// 起動時に致命的なエラーが起きたときの画面。
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 起動の最初期の画面なので、設定で選んだ言語（Riverpod）には頼らず、端末の言語に従う
      // （i18n設計書 3.3）。
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // MaterialApp の下で Localizations が決まるので、Builder の context で引く。
                Builder(
                  builder: (context) => Text(
                    AppLocalizations.of(context)!.startupErrorTitle,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                // 接続先の間違いや通信の不調が分かるように、理由も出す。
                Text('$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
