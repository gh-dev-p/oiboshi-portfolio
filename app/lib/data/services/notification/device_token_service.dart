import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/supabase_names.dart';

/// 通知の送り先（`device_tokens`。データ設計書 3.1.22）の読み書き。
class DeviceTokenService {
  DeviceTokenService(this._client);

  final SupabaseClient _client;

  /// いまのユーザーの端末として登録する。ほかのユーザーの行なら、いまのユーザーに移る。
  /// [language] は、通知の文言の言語（`ja`・`en`）。
  Future<void> register(String token, String platform, String language) =>
      _client.rpc<void>(
        Functions.registerDeviceToken,
        params: {
          'p_token': token,
          'p_platform': platform,
          'p_language': language,
        },
      );

  /// いまのユーザーの、その端末の登録を消す。
  Future<void> delete(String token) =>
      _client.from(Tables.deviceTokens).delete().eq('token', token);
}
