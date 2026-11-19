import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../core/view_models/auth_session_provider.dart';
import '../../core/view_models/refresh.dart';
import '../../settings/view_models/settings_providers.dart';
import 'oshi_providers.dart';

/// 推しを探す・推しを選ぶに出すもの（検索の言葉、発信者、フォロー中の発信者）。
class CreatorSearchState {
  const CreatorSearchState({
    this.query = '',
    String? resultQuery,
    this.creators = const AsyncLoading(),
    this.followedIds = const {},
  }) : resultQuery = resultQuery ?? query;

  /// 検索の言葉（入力中のもの）。空なら、おすすめを出す。
  final String query;

  /// [creators] が、どの言葉の結果か。新しい言葉の結果が届くまでは、前の言葉のまま（[query] と違うことがある）。
  final String resultQuery;

  /// 出す発信者（[resultQuery] が空なら、おすすめ）。読み込み中と失敗も、ここに入る。
  final AsyncValue<List<Creator>> creators;

  /// フォロー中の発信者 ID。
  final Set<String> followedIds;

  bool isFollowing(String creatorId) => followedIds.contains(creatorId);

  /// 言葉を入れて探し、合う発信者がいないか（推しを探す（結果なし）。画面定義書 2.3.3）。
  /// 出している結果の言葉で決める（まだ探していない言葉で、「合う推しは…」を出さない）。
  bool get noMatch =>
      resultQuery.trim().isNotEmpty && (creators.value?.isEmpty ?? false);

  /// 見出し「おすすめ」を出すか（画面定義書 2.3.2）。出している一覧がおすすめで、1人以上いるとき。
  /// 言葉を入れても、検索の結果が届くまでは、おすすめと一緒に出しておく。
  bool get showsRecommended =>
      resultQuery.trim().isEmpty && (creators.value?.isNotEmpty ?? false);

  CreatorSearchState copyWith({String? query}) => CreatorSearchState(
    query: query ?? this.query,
    resultQuery: resultQuery,
    creators: creators,
    followedIds: followedIds,
  );
}

/// 推しを探す・推しを選ぶで同じ操作（検索・フォロー・再試行）。
/// 画面ごとの ViewModel がこれを継ぐ。Provider は画面ごとに分け、状態を共有しない。
abstract class CreatorSearchNotifier extends Notifier<CreatorSearchState> {
  @override
  CreatorSearchState build() {
    // 検索している間も、おすすめを持っておく（言葉を消したら、同じ一覧に戻す）。
    ref.listen(recommendedCreatorsProvider, (_, _) {});
    final previous = stateOrNull;
    final query = previous?.query ?? '';
    var resultQuery = query;
    var creators = ref.watch(searchedCreatorsProvider(query));
    if (creators is AsyncLoading && (previous?.creators.hasValue ?? false)) {
      // 言葉を変えた直後は、新しい結果が来るまで、前の結果を、その言葉と一緒に出したままにする。
      // 前が失敗なら残さない（「もう一度試す」で、読み込み中に戻す）。
      creators = previous!.creators;
      resultQuery = previous.resultQuery;
    }
    // 表示しないにした発信者は、手元でも除く（機能仕様書 4.2.6）。おすすめは開いている間は選び直さないので、
    // 開いたあとに発信者ページで表示しないにした発信者も、ここで消す。読めない間は除かない。
    final hidden = {
      for (final c in ref.watch(hiddenCreatorsProvider).value ?? const []) c.id,
    };
    if (hidden.isNotEmpty) {
      creators = creators.whenData(
        (list) => [
          for (final c in list)
            if (!hidden.contains(c.id)) c,
        ],
      );
    }
    return CreatorSearchState(
      query: query,
      resultQuery: resultQuery,
      creators: creators,
      followedIds: ref.watch(followedIdsProvider),
    );
  }

  /// 検索の言葉を変える。結果は、言葉ごとの Provider から読み直す。
  void setQuery(String query) {
    if (query == state.query) return;
    state = state.copyWith(query: query);
    ref.invalidateSelf();
  }

  /// フォローを切り替える。失敗したら false。
  Future<bool> toggleFollow(String creatorId) =>
      ref.read(followActionsProvider.notifier).toggle(creatorId);

  /// 「もう一度試す」。サインインからやり直し、おすすめと検索の結果（と、表示しない発信者）を読み直す。
  void retry() => reloadFrom(ref, [
    authSessionProvider,
    recommendedCreatorsProvider,
    searchedCreatorsProvider,
    hiddenCreatorsProvider,
  ]);
}
