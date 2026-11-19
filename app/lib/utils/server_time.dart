/// サーバーの日時（ISO 8601）を、端末のローカル時刻で読む。
DateTime? parseTime(String? value) =>
    value == null ? null : DateTime.parse(value).toLocal();

/// サーバーに渡す日時の形。
extension ServerTime on DateTime {
  /// UTC の ISO 8601 の文字列。
  String toServerTime() => toUtc().toIso8601String();
}
