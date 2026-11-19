import '../../../domain/models/sns_account_input.dart';
import '../../../domain/models/want.dart';
import '../../services/want/want_service.dart';

/// 追いたい（機能仕様書（届ける・広める）4.5.1）。
class WantRepository {
  WantRepository(this._service);

  final WantService _service;

  /// 追いたいを押す。送れなかったときも、例外ではなく [WantFailed] を返す。
  Future<WantResult> want(SnsAccountInput input) async {
    try {
      return WantResult.fromServer(
        await _service.want(input.service.name, input.account),
      );
    } catch (_) {
      return const WantFailed();
    }
  }

  /// 自分が押した追いたい（新しい順）。
  Future<List<Want>> fetchMine() async => [
    for (final row in await _service.fetchMine()) ?Want.fromRow(row),
  ];

  /// 取り消す。
  Future<void> cancel(String wantedAccountId) =>
      _service.cancel(wantedAccountId);
}
