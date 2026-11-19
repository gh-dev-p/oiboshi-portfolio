import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'creator_search_state.dart';

/// 推しを探す（画面定義書 2.3.2）。「おすすめ」の一覧と検索。
class FindCreatorsViewModel extends CreatorSearchNotifier {}

final findCreatorsViewModelProvider =
    NotifierProvider.autoDispose<FindCreatorsViewModel, CreatorSearchState>(
      FindCreatorsViewModel.new,
    );
