/// 操作を行い、例外が出たら [onError] を返す。状態を持たない操作の ViewModel が、失敗を結果の値（enum など）で
/// View に返すときに使う（アーキテクチャ設計書 4.2）。
Future<R> guard<R>(Future<R> Function() action, {required R onError}) async {
  try {
    return await action();
  } catch (_) {
    return onError;
  }
}

/// 操作を行い、済んだら true、例外が出たら false を返す（[guard]）。
Future<bool> succeeded(Future<void> Function() action) => guard(() async {
  await action();
  return true;
}, onError: false);
