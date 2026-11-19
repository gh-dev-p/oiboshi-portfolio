import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_settings.dart';
import '../../../domain/models/sns_service.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';
import 'creator_admin_providers.dart';

/// アカウント連携（画面定義書 2.3.2）。状態は、連携したアカウント（未確認を含む）。
/// [creatorId] が null のとき（発信者として登録の手順から開いた）は、登録待ちの連携（機能仕様書 4.6.1）を扱う。
class AccountLinkViewModel
    extends AsyncNotifier<Map<SnsService, CreatorAccount>> {
  AccountLinkViewModel(this.creatorId);

  /// 登録の手順から開いたときは null（まだ発信者がいない）。
  final String? creatorId;

  @override
  Future<Map<SnsService, CreatorAccount>> build() async {
    final id = creatorId;
    if (id == null) return ref.watch(pendingAccountLinksProvider.future);
    final data = await ref.watch(creatorAdminDataProvider(id).future);
    return data.creator.linkedAccounts;
  }

  /// 読み込めなかったときに、読み直す。
  void retry() {
    ref.invalidate(authSessionProvider);
    _refresh();
  }

  /// 連携を変えたあとに、それを出している Provider を読み直す。
  void _refresh() {
    final id = creatorId;
    if (id == null) {
      ref.invalidate(pendingAccountLinksProvider);
    } else {
      refreshCreatorAdmin(ref, id);
    }
  }

  /// SNS のアカウントを、OAuth で連携する。連携できたら（取り戻せる発信者が見つかったときも）、読み直す。
  Future<AccountLinkResult> linkAccount(SnsService service) async {
    final result = await guard(
      () => ref
          .read(creatorAdminRepositoryProvider)
          .linkAccount(creatorId, service),
      onError: AccountLinkResult.failed,
    );
    if (result == AccountLinkResult.linked ||
        (creatorId == null && result == AccountLinkResult.reclaimable)) {
      _refresh();
    }
    return result;
  }

  /// 連携を解除する。失敗したら false。
  Future<bool> unlinkAccount(SnsService service) async {
    final repo = ref.read(creatorAdminRepositoryProvider);
    final id = creatorId;
    return succeeded(() async {
      if (id == null) {
        await repo.unlinkPendingAccount(service);
      } else {
        await repo.unlinkAccount(id, service);
      }
      _refresh();
    });
  }
}

final accountLinkViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<AccountLinkViewModel, Map<SnsService, CreatorAccount>, String?>(
      AccountLinkViewModel.new,
    );
