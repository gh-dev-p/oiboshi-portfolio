import 'package:flutter_riverpod/flutter_riverpod.dart';

/// この起動のあいだに、発信者が隠した投稿の ID（機能仕様書 4.4.4）。
/// 投稿を出している Provider（ホーム・発信者ページ・スケジュール）が聞き、変わったら読み直す。
/// ホームは、続きで読んだ投稿も持っているので、ここにある投稿を外す。
class RemovedPosts extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// [postId] を隠した。
  void add(String postId) => state = {...state, postId};

  /// [postId] をまた出した。前の起動で隠した投稿（ここにない投稿）でも、聞いている画面が読み直すよう、知らせる。
  void restore(String postId) => state = {...state}..remove(postId);
}

final removedPostsProvider = NotifierProvider<RemovedPosts, Set<String>>(
  RemovedPosts.new,
);
