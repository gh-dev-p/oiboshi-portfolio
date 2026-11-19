import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 画面全体の読み込みの状態に合わせて、本体を選ぶ（画面定義書 5.1.3）。
///
/// 値があれば、読み直し中・更新の失敗のときも、内容を出す。値がなければ、読み込み中を先に見て
/// スケルトンを出す（Riverpod 3 は、失敗のあとの読み直しで、エラーを残したまま読み込み中にするため。
/// 「もう一度試す」で、読み込み中に戻す）。値がなく失敗なら、「読み込めない」を出す。
Widget asyncBody<T>(
  AsyncValue<T> value, {
  required Widget Function(T data) data,
  required Widget Function() loading,
  required Widget Function() error,
}) {
  if (value.hasValue) return data(value.requireValue);
  if (value.isLoading || !value.hasError) return loading();
  return error();
}

/// 表示済みの内容があるときの更新の失敗か。true なら、スナックバー（「更新できませんでした」と「再試行」）を出す。
///
/// 読み込み中は出さない（「再試行」のあとも、エラーを残したまま読み込み中になるため）。
/// 前の状態が同じ失敗のままなら、もう一度は出さない。
/// 表示済みの内容を [next] の外で持つ画面は、[hasContent] で、内容があるかを渡す。
bool isRefreshFailure(
  AsyncValue<Object?>? previous,
  AsyncValue<Object?> next, {
  bool? hasContent,
}) {
  if (!(hasContent ?? next.hasValue) || !next.hasError || next.isLoading) {
    return false;
  }
  return previous == null || previous.isLoading || !previous.hasError;
}
