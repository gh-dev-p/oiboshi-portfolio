import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase のログインの情報を、端末の安全な保存場所（iOS のキーチェーン、Android の Keystore）に置く（機能仕様書 4.1.1）。
/// 以前の保存場所（SharedPreferences）に残っていれば、初回に移して消す（匿名のユーザーが変わって、フォローが消えないように）。
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({required this.persistSessionKey});

  /// supabase_flutter の既定と同じキー（`sb-{プロジェクト}-auth-token`）。
  final String persistSessionKey;

  /// iCloud で同期せず、再起動後の最初のロック解除からは、裏でも読める（トークンの更新のため）。
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// URL から、supabase_flutter の既定のキーを作る。
  static String keyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(persistSessionKey);
    if (legacy == null) return;
    if (await _storage.read(key: persistSessionKey) == null) {
      await _storage.write(key: persistSessionKey, value: legacy);
    }
    await prefs.remove(persistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: persistSessionKey);

  @override
  Future<String?> accessToken() => _storage.read(key: persistSessionKey);

  @override
  Future<void> removePersistedSession() =>
      _storage.delete(key: persistSessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: persistSessionKey, value: persistSessionString);
}
