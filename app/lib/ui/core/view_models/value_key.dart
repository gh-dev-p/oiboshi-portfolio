import 'package:flutter/foundation.dart' show listEquals;

/// `.family` のキーに使う、値で等しさを決めるクラスの基底（アーキテクチャ設計書 4.2）。
/// 型と [props] の値で比べる。[props] に入れた一覧（List）は、中身で比べる。
abstract class ProviderKey {
  const ProviderKey();

  /// 等しさを決める値。
  List<Object?> get props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProviderKey || other.runtimeType != runtimeType) return false;
    final a = props;
    final b = other.props;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x is List && y is List ? !listEquals(x, y) : x != y) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
    for (final p in props) p is List ? Object.hashAll(p) : p,
  ]);
}
