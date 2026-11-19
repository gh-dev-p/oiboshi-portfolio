import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';
import '../../../domain/models/sns_account_input.dart';
import '../../../domain/models/want.dart';
import '../../core/view_models/auth_session_provider.dart';

/// 追いたい（画面定義書 2.3.4）。自分が押した一覧（新しい順）と、押す・取り消す。
class WantViewModel extends AsyncNotifier<List<Want>> {
  @override
  Future<List<Want>> build() =>
      withSession(ref, (_) => ref.watch(wantRepositoryProvider).fetchMine());

  /// 追いたいを押す。押したら、一覧を読み直す（押した人数も新しくする）。
  Future<WantResult> want(SnsAccountInput input) async {
    final result = await ref.read(wantRepositoryProvider).want(input);
    if (result is WantAdded) await _reload();
    return result;
  }

  /// 取り消す。先に一覧から外し、失敗したら戻す。失敗したら false。
  Future<bool> cancel(String wantedAccountId) async {
    final before = state.value;
    if (before != null) {
      state = AsyncData([
        for (final w in before)
          if (w.wantedAccountId != wantedAccountId) w,
      ]);
    }
    try {
      await ref.read(wantRepositoryProvider).cancel(wantedAccountId);
      return true;
    } catch (_) {
      if (before != null) state = AsyncData(before);
      return false;
    }
  }

  /// 「もう一度試す」。サインインからやり直す。
  void retry() {
    ref.invalidate(authSessionProvider);
    ref.invalidateSelf();
  }

  Future<void> _reload() async {
    try {
      state = AsyncData(await ref.read(wantRepositoryProvider).fetchMine());
    } catch (_) {
      // 読み直せなくても、押したことは済んでいる。一覧は次に開いたときに読む。
    }
  }
}

final wantViewModelProvider =
    AsyncNotifierProvider.autoDispose<WantViewModel, List<Want>>(
      WantViewModel.new,
    );
