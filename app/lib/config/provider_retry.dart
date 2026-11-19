/// Provider の自動再試行（Riverpod 3 の既定）を行わない設定。`ProviderScope` の `retry` に渡す。
///
/// 既定では、失敗した Provider を間隔を空けて作り直し、その間はエラーではなく読み込み中のままになる。
/// 追星では、エラーをそのまま画面に出し、再試行はユーザーの操作（「もう一度試す」「再試行」）で行う。
Duration? noProviderRetry(int retryCount, Object error) => null;
