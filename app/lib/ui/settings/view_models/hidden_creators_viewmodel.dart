import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/creator.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/guard.dart';
import '../../core/view_models/refresh.dart';
import '../../oshi/view_models/oshi_providers.dart';
import 'settings_providers.dart';

/// 表示しない発信者（画面定義書（設定・発信者向け）2.1.10）。一覧し、「表示する」で戻す。
class HiddenCreatorsViewModel extends AsyncNotifier<List<Creator>> {
  @override
  Future<List<Creator>> build() => ref.watch(hiddenCreatorsProvider.future);

  /// 表示するように戻す（フォローは戻さない）。失敗したら false。
  Future<bool> unhide(String creatorId) async {
    if (!await succeeded(
      () => ref.read(hiddenCreatorRepositoryProvider).unhide(creatorId),
    )) {
      return false;
    }
    if (ref.mounted) {
      ref
        ..invalidate(hiddenCreatorsProvider)
        ..invalidate(searchedCreatorsProvider);
    }
    return true;
  }

  /// 読み込めなかったときに、読み直す。
  void retry() =>
      reloadFrom(ref, [authSessionProvider, hiddenCreatorsProvider]);
}

final hiddenCreatorsViewModelProvider =
    AsyncNotifierProvider.autoDispose<HiddenCreatorsViewModel, List<Creator>>(
      HiddenCreatorsViewModel.new,
    );
