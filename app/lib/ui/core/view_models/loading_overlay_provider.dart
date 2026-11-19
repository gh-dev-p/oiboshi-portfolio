import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ボタンを押したときなどの非同期処理中に、画面全体をブロックする表示の状態。
/// 状態は「実行中の処理の数」。各 ViewModel は、処理を [run] で囲む。
class LoadingOverlayController extends Notifier<int> {
  @override
  int build() => 0;

  Future<T> run<T>(Future<T> Function() action) async {
    state++;
    try {
      return await action();
    } finally {
      state--;
    }
  }
}

final loadingOverlayProvider = NotifierProvider<LoadingOverlayController, int>(
  LoadingOverlayController.new,
);
