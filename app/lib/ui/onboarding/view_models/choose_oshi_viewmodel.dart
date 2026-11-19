import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../oshi/view_models/creator_search_state.dart';

/// 推しを選ぶ（画面定義書 2.1.2）。おすすめの一覧と検索から、最初にフォローする推しを選ぶ。
class ChooseOshiViewModel extends CreatorSearchNotifier {}

final chooseOshiViewModelProvider =
    NotifierProvider.autoDispose<ChooseOshiViewModel, CreatorSearchState>(
      ChooseOshiViewModel.new,
    );
