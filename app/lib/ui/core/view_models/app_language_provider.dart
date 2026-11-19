import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/user_settings.dart';
import '../../../l10n/app_localizations.dart';
import 'stored_setting.dart';

/// 表示言語（機能仕様書 4.7.2、i18n設計書 3.2）。端末内に保存する。
/// 選んだ言語は、`MaterialApp.locale` にすぐ反映するので、アプリの再起動は要らない。
class AppLanguageNotifier extends StoredSetting<AppLanguage> {
  @override
  AppLanguage load(SettingsRepository repo) => repo.appLanguage;

  @override
  Future<void> save(SettingsRepository repo, AppLanguage value) =>
      repo.setAppLanguage(value);

  Future<void> set(AppLanguage language) async {
    state = language;
    await store(language);
  }
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

extension AppLanguageLocale on AppLanguage {
  /// `MaterialApp.locale` に渡す値。端末の設定に従うときは null にして、端末の言語の優先順から
  /// Flutter に選ばせる（日本語・英語のどちらでもなければ、`supportedLocales` の先頭の英語）。
  Locale? get locale => switch (this) {
    AppLanguage.system => null,
    AppLanguage.ja => const Locale('ja'),
    AppLanguage.en => const Locale('en'),
  };

  /// 通知の文言の言語（`ja`・`en`。i18n設計書 6.5）。アプリの表示言語と同じにする。端末の設定に従うときは、
  /// `MaterialApp` と同じ決め方で、[deviceLocales]（省略すると端末の言語の優先順）から選ぶ。
  String notificationLanguage([List<Locale>? deviceLocales]) =>
      (locale ??
              basicLocaleListResolution(
                deviceLocales ?? PlatformDispatcher.instance.locales,
                AppLocalizations.supportedLocales,
              ))
          .languageCode;
}
