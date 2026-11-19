import 'package:supabase_flutter/supabase_flutter.dart';

import '../common/edge_functions.dart';
import '../common/supabase_names.dart';
import '../common/web_auth.dart';

/// アカウント連携（OAuth）。サーバー（Edge Function `link-account`）で始め、
/// アプリ内のブラウザで SNS のログインと許可を済ませ、`oiboshi://` で戻ってくる。
class AccountLinkService {
  AccountLinkService(this._client);

  final SupabaseClient _client;

  /// SNS のログインと許可の画面の URL。[creatorId] が null なら、発信者として登録の手順からの連携。
  Future<String> startUrl(String? creatorId, String service) =>
      _client.functions.invokeResult<String>(
        EdgeFunctions.linkAccountStart,
        body: {'creatorId': creatorId, 'service': service},
        key: 'url',
      );

  /// 発信者として登録の手順で連携した、登録待ちのアカウント。
  Future<List<Map<String, dynamic>>> fetchPending() => _client
      .from(Tables.pendingAccountLinks)
      .select('service, account, handle, verified_at');

  /// 登録待ちの連携を解除する（本人の行だけ消せる）。
  Future<void> deletePending(String service) =>
      _client.from(Tables.pendingAccountLinks).delete().eq('service', service);

  /// ブラウザで [url] を開き、戻ってきた URL の `result` を返す。閉じたら null。
  Future<String?> authenticate(String url) async {
    final callback = await authenticateInBrowser(url);
    return callback == null
        ? null
        : Uri.parse(callback).queryParameters['result'];
  }
}
