import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 端末内に保存した設定（初回起動の完了、画面モード、表示言語）の読み書き先。
/// 起動時（`bootstrap.dart`）に読み込み済みのインスタンスで上書きする。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider は起動時に上書きする'),
);
