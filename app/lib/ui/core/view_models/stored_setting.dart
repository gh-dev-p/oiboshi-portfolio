import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../data/repositories/settings/settings_repository.dart';

/// 端末内に保存する設定の Notifier の基底。起動時の値は [load] で読み、[store] で書く。
/// 書く順番（先に state を変えるか、書いてから変えるか）と、同じ値なら何もしない処理は、使う側のクラスで決める。
abstract class StoredSetting<T> extends Notifier<T> {
  /// 端末内の保存から読む。
  T load(SettingsRepository repo);

  /// 端末内に書く。
  Future<void> save(SettingsRepository repo, T value);

  @override
  T build() => load(ref.watch(settingsRepositoryProvider));

  /// [value] を端末内に書く（state は変えない）。
  Future<void> store(T value) =>
      save(ref.read(settingsRepositoryProvider), value);
}
