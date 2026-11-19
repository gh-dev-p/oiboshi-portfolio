import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../core/view_models/stored_setting.dart';

/// 初回起動が済んでいるか（端末内に保存）。アプリの土台が、起動時の振り分けに使う。
class OnboardingDone extends StoredSetting<bool> {
  @override
  bool load(SettingsRepository repo) => repo.onboardingDone;

  /// 済みにすることしかないので、[value] は使わない。
  @override
  Future<void> save(SettingsRepository repo, bool value) =>
      repo.setOnboardingDone();

  /// 初回起動を済みにする。端末に保存できなくても、済みにして進む（画面定義書（ファン向け）2.1.3。
  /// 次に開いたとき、初回起動をもう一度出すだけで済むため）。
  Future<void> complete() async {
    try {
      await store(true);
    } catch (e) {
      debugPrint('初回起動を済ませた印を保存できない: $e');
    }
    state = true;
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingDone, bool>(
  OnboardingDone.new,
);
