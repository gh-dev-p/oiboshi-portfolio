import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:oiboshi/config/preferences_provider.dart';
import 'package:oiboshi/config/provider_retry.dart';
import 'package:oiboshi/config/service_providers.dart';
import 'package:oiboshi/l10n/app_localizations.dart';
import 'package:oiboshi/ui/core/themes/app_theme.dart';
import 'package:oiboshi/ui/core/view_models/app_language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'fake_announce_image_repository.dart';
import 'fake_auth_repository.dart';
import 'fake_billing_repository.dart';
import 'fake_creator_admin_repository.dart';
import 'fake_creator_link_repository.dart';
import 'fake_creator_repository.dart';
import 'fake_data.dart';
import 'fake_follow_repository.dart';
import 'fake_image_picker_service.dart';
import 'fake_instagram_dm_repository.dart';
import 'fake_notification_repository.dart';
import 'fake_post_repository.dart';
import 'fake_post_view_repository.dart';
import 'fake_reach_repository.dart';
import 'fake_report_repository.dart';
import 'fake_schedule_repository.dart';
import 'fake_settings_repository.dart';
import 'fake_share.dart';
import 'fake_want_repository.dart';
import 'fake_webview.dart';

/// テスト用の差し替え。Repository を、[data] を読み書きするフェイクにする。
Future<List<Override>> testOverrides(
  FakeData data, {
  FakeNotificationRepository? notification,
  FakeAppLinkService? links,
  FakeShareSheetService? shareSheet,
  FakeClipboardService? clipboard,
  FakeReachRepository? reach,
  FakePostViewRepository? postViews,
}) async {
  SharedPreferences.setMockInitialValues({});
  WebViewPlatform.instance = FakeWebViewPlatform();
  final prefs = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(data)),
    creatorRepositoryProvider.overrideWithValue(FakeCreatorRepository(data)),
    followRepositoryProvider.overrideWithValue(FakeFollowRepository(data)),
    hiddenCreatorRepositoryProvider.overrideWithValue(
      FakeHiddenCreatorRepository(data),
    ),
    reportRepositoryProvider.overrideWithValue(FakeReportRepository(data)),
    wantRepositoryProvider.overrideWithValue(FakeWantRepository(data)),
    postRepositoryProvider.overrideWithValue(FakePostRepository(data)),
    scheduleRepositoryProvider.overrideWithValue(FakeScheduleRepository(data)),
    settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository(data)),
    notificationRepositoryProvider.overrideWithValue(
      notification ?? FakeNotificationRepository(),
    ),
    creatorAdminRepositoryProvider.overrideWithValue(
      FakeCreatorAdminRepository(data),
    ),
    billingRepositoryProvider.overrideWithValue(FakeBillingRepository(data)),
    instagramDmRepositoryProvider.overrideWithValue(
      FakeInstagramDmRepository(data),
    ),
    appLinkServiceProvider.overrideWithValue(links ?? FakeAppLinkService()),
    shareSheetServiceProvider.overrideWithValue(
      shareSheet ?? FakeShareSheetService(),
    ),
    clipboardServiceProvider.overrideWithValue(
      clipboard ?? FakeClipboardService(),
    ),
    reachRepositoryProvider.overrideWithValue(reach ?? FakeReachRepository()),
    postViewRepositoryProvider.overrideWithValue(
      postViews ?? FakePostViewRepository(),
    ),
    creatorLinkRepositoryProvider.overrideWithValue(
      FakeCreatorLinkRepository(data),
    ),
    announceImageRepositoryProvider.overrideWithValue(
      FakeAnnounceImageRepository(data),
    ),
  ];
}

/// テスト用のアプリ。Repository を差し替えた `ProviderScope` で [home] を出す。
/// 表示言語は、端末の言語に左右されないように、[locale]（既定は日本語）に決める。
/// [locale] に null を渡すと、アプリと同じく、設定で選んだ表示言語（`appLanguageProvider`）に従う。
/// [picker] を渡すと、端末の写真を選ぶ代わりに使う。
Future<Widget> testApp(
  FakeData data,
  Widget home, {
  FakeNotificationRepository? notification,
  FakeImagePickerService? picker,
  FakeAppLinkService? links,
  FakeShareSheetService? shareSheet,
  FakeClipboardService? clipboard,
  FakeReachRepository? reach,
  FakePostViewRepository? postViews,
  Locale? locale = const Locale('ja'),
  ThemeData? theme,
}) async {
  return ProviderScope(
    retry: noProviderRetry,
    overrides: [
      ...await testOverrides(
        data,
        notification: notification,
        links: links,
        shareSheet: shareSheet,
        clipboard: clipboard,
        reach: reach,
        postViews: postViews,
      ),
      if (picker != null) imagePickerServiceProvider.overrideWithValue(picker),
    ],
    child: Consumer(
      builder: (context, ref, _) => MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale ?? ref.watch(appLanguageProvider).locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}
