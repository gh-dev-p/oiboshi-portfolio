import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// ユーザーごとの通知の設定の読み書き。
class UserSettingsService {
  UserSettingsService(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetch() =>
      _client.from(Tables.userSettings).select().maybeSingle();

  /// 行がなければ作り、あれば更新する。
  Future<void> save(bool notificationsEnabled) => _client
      .from(Tables.userSettings)
      .upsert({'notifications_enabled': notificationsEnabled});
}
