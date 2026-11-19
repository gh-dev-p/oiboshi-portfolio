/// Repository が返すエラーの種別。文言への変換は View で行う。
enum AppErrorKind {
  network,
  auth,
  notFound,

  /// 回数の上限を超えた（しばらく時間をおけば、また使える）。
  rateLimited,
  unknown,
}

class AppException implements Exception {
  const AppException(this.kind, [this.cause]);

  final AppErrorKind kind;
  final Object? cause;

  @override
  String toString() => 'AppException($kind, $cause)';
}
