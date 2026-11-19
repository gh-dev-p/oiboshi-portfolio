import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// 検索で、表記の揺れを同じ字にそろえる（機能仕様書 4.2.2）。
/// サーバーの `search_normalize` と同じく、NFKC で全角と半角（英数字・記号・カタカナ）を、
/// カタカナ（ァ〜ヶ）をひらがなに、英字を小文字にする（手元とサーバーで、同じ言葉が同じ発信者に合うように）。
String normalizeForSearch(String text) {
  final out = StringBuffer();
  for (final r in unorm.nfkc(text).runes) {
    out.writeCharCode(r >= 0x30A1 && r <= 0x30F6 ? r - 0x60 : r);
  }
  return out.toString().toLowerCase();
}
