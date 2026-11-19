/// サーバーや端末に保存した名前から、enum の値を引く。
extension EnumByName<T extends Enum> on Iterable<T> {
  /// 名前が [name] の値。知らない名前なら null。
  T? byNameOrNull(Object? name) {
    for (final v in this) {
      if (v.name == name) return v;
    }
    return null;
  }
}
