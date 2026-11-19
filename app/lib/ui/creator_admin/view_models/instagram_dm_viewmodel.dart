// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1）。
// Meta の審査が通るまでの、一時的な仕組み。通ったら、このファイルごと外す。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/instagram_dm.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';

/// DM の確認の状態（受け先と、確かめを待っているコード）。
/// [creatorId] が null のとき（発信者として登録の手順から開いた）は、登録の手順のコードを扱う。
class InstagramDmViewModel extends AsyncNotifier<InstagramDmState> {
  InstagramDmViewModel(this.creatorId);

  final String? creatorId;

  @override
  Future<InstagramDmState> build() => withSession(
    ref,
    (_) => ref.watch(instagramDmRepositoryProvider).fetchState(creatorId),
  );

  /// 読み込めなかったときに、読み直す。
  void retry() {
    ref.invalidate(authSessionProvider);
    ref.invalidateSelf();
  }

  /// コードを出す。出せたら、読み直す。
  Future<InstagramDmRequestResult> request(String account) async {
    final result = await guard(
      () => ref.read(instagramDmRepositoryProvider).request(creatorId, account),
      onError: InstagramDmRequestResult.failed,
    );
    if (result == InstagramDmRequestResult.requested) ref.invalidateSelf();
    return result;
  }

  /// コードを取り消す。失敗したら false。
  Future<bool> cancel() async {
    final request = state.value?.request;
    if (request == null) return true;
    if (!await succeeded(
      () => ref.read(instagramDmRepositoryProvider).cancel(request.id),
    )) {
      return false;
    }
    ref.invalidateSelf();
    return true;
  }
}

final instagramDmViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<InstagramDmViewModel, InstagramDmState, String?>(
      InstagramDmViewModel.new,
    );
