import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// 接続先。`flutter run --flavor {dev|prod} -t lib/main_{dev|prod}.dart --dart-define-from-file=dart_defines.{dev|prod}.json` で渡す（アーキテクチャ設計書 6章、環境構成 10）。
abstract final class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// RevenueCat の公開用の SDK キー。空なら、その端末で課金の機能を出さない（機能仕様書 4.6.6）。
  static const revenueCatIosKey = String.fromEnvironment(
    'REVENUECAT_IOS_API_KEY',
  );
  static const revenueCatAndroidKey = String.fromEnvironment(
    'REVENUECAT_ANDROID_API_KEY',
  );

  /// Firebase（通知の FCM）の接続の値。設定ファイルは使わない（環境構成 2）。
  static const _firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const _firebaseSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );
  static const _firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const _firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );

  /// この端末の Firebase の接続の値。値がそろっていなければ null で、通知の送り先を登録しない（機能仕様書 4.3.3）。
  static FirebaseOptions? get firebaseOptions {
    final (appId, apiKey) = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => (_firebaseIosAppId, _firebaseIosApiKey),
      TargetPlatform.android => (_firebaseAndroidAppId, _firebaseAndroidApiKey),
      _ => ('', ''),
    };
    if ([
      appId,
      apiKey,
      _firebaseProjectId,
      _firebaseSenderId,
    ].any((v) => v.isEmpty)) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: _firebaseSenderId,
      projectId: _firebaseProjectId,
    );
  }
}
