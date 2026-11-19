import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/sns_service.dart';
import '../../core/view_models/guard.dart';
import 'creator_admin_providers.dart';

/// 表示する内容（画面定義書 2.3.3）。連携したアカウントごとに、追星に出す内容を選ぶ。
class DisplayContentsViewModel extends CreatorAdminDataNotifier {
  DisplayContentsViewModel(super.creatorId);

  /// 読み込めなかったときに、読み直す。
  void retry() => retryCreatorAdmin(ref, creatorId);

  /// [service] の [content] を出すかを変える。変えたら読み直す。失敗したら false。
  Future<bool> setDisplay(
    SnsService service,
    DisplayContent content,
    bool enabled,
  ) => succeeded(() async {
    await ref
        .read(creatorAdminRepositoryProvider)
        .setDisplay(creatorId, service, content, enabled);
    refreshCreatorAdmin(ref, creatorId);
  });
}

final displayContentsViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<DisplayContentsViewModel, CreatorAdminData, String>(
      DisplayContentsViewModel.new,
    );
