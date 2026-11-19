import 'dart:convert';

/// WebView で動かした JavaScript の結果を文字列にする。Android は、JSON の文字列（引用符つき）で返すので、ほどく。
String jsResultToString(Object result) {
  if (result is! String) return result.toString();
  if (result.length >= 2 && result.startsWith('"') && result.endsWith('"')) {
    try {
      return jsonDecode(result) as String;
    } catch (_) {
      return result;
    }
  }
  return result;
}
