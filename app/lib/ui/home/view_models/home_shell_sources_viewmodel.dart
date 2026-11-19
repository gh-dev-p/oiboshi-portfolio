import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../creator/view_models/creator_providers.dart';
import '../../settings/view_models/settings_providers.dart';

/// ホームの枠が、ほかの機能から受け取る状態（自分がオーナーの発信者と、流している配信が終わった知らせ）。
class HomeShellSourcesState {
  const HomeShellSourcesState({required this.owned, this.liveEnded});

  /// 自分がオーナーの発信者（[ownedCreatorProvider]）。発信者のタブを出すか決める。
  final AsyncValue<Creator?> owned;

  /// 流していた配信が終わった知らせ（[liveEndWatcherProvider]）。知らせるたびに、別のものになる。
  final LiveEnded? liveEnded;
}

/// ほかの機能の Provider を聞いて、state に写す。ホームの枠の View が見ている間だけ生きる（`.autoDispose`）。
/// タブの選択（[HomeShellViewModel]）と分けるのは、autoDispose の [ownedCreatorProvider] の寿命を、
/// ホームの枠の View が見ている間のままにするため。build で watch せず listen するのは、
/// 知らせを、出たその時に（[liveEndWatcherProvider] が null に戻る前に）伝えるため。
class HomeShellSourcesViewModel extends Notifier<HomeShellSourcesState> {
  @override
  HomeShellSourcesState build() {
    final owned = ref.listen(
      ownedCreatorProvider,
      (_, next) => state = HomeShellSourcesState(
        owned: next,
        liveEnded: state.liveEnded,
      ),
    );
    ref.listen(
      liveEndWatcherProvider,
      (_, next) =>
          state = HomeShellSourcesState(owned: state.owned, liveEnded: next),
    );
    return HomeShellSourcesState(owned: owned.read());
  }
}

final homeShellSourcesViewModelProvider =
    NotifierProvider.autoDispose<
      HomeShellSourcesViewModel,
      HomeShellSourcesState
    >(HomeShellSourcesViewModel.new);
