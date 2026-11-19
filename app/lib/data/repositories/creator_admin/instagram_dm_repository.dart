// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1）。
// Meta の審査が通るまでの、一時的な仕組み。通ったら、このファイルごと外す。
import '../../../domain/models/instagram_dm.dart';
import '../../services/creator/instagram_dm_service.dart';
import '../common/error_mapping.dart';

/// DM の確認の状態を読み、コードを出す・取り消す。
class InstagramDmRepository {
  InstagramDmRepository(this._service);

  final InstagramDmService _service;

  /// [creatorId] が null なら、発信者として登録の手順から。DM の手順を使わないときは、コードを読まない。
  Future<InstagramDmState> fetchState(String? creatorId) => mapErrors(() async {
    final dmAccount = await _service.fetchDmAccount();
    if (dmAccount == null) return const InstagramDmState();
    final row = await _service.fetchRequest(creatorId);
    return InstagramDmState(
      dmAccount: dmAccount,
      request: row == null ? null : InstagramDmRequest.fromRow(row),
    );
  });

  Future<InstagramDmRequestResult> request(String? creatorId, String account) =>
      mapErrors(() async {
        final res = await _service.request(creatorId, account);
        return InstagramDmRequestResult.fromServer(res['result'] as String?);
      });

  Future<void> cancel(String requestId) =>
      mapErrors(() => _service.delete(requestId));
}
