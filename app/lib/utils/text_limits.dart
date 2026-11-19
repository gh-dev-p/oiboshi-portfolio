import 'package:flutter/widgets.dart' show StringCharacters;

/// 見た目の1文字（書記素）で数えた長さ。絵文字（合字・肌の色・旗）も1文字と数える。
/// 入力欄の `maxLength` と同じ数え方（機能仕様書 4.5.2・4.6.4）。
int graphemeLength(String text) => text.characters.length;

/// 見た目の1文字（書記素）で [max] 文字に収まるように切る。絵文字の途中では切らない。
String clampGraphemes(String text, int max) {
  final chars = text.characters;
  return chars.length <= max ? text : chars.take(max).toString();
}

/// イベントのリンクの形（`https://` で始まり、ホストがあり、空白を含まない）。
/// データベースの制約 `schedules_ticket_url_https`（データ設計書 3.1.16）と同じ。
final _httpsUrl = RegExp(r'^https://[^\s/?#]+\S*$');

/// [text] が、イベントのリンクとして受け付ける URL か（機能仕様書 4.5.2）。
bool isHttpsUrl(String text) {
  if (!_httpsUrl.hasMatch(text)) return false;
  final uri = Uri.tryParse(text);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}
