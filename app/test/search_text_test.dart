import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/utils/search_text.dart';

void main() {
  // サーバーの search_normalize と同じ結果になること（tech-risks.md 2.26）。
  // supabase/tests/database/search.test.sql に同じ例を置く。どちらかを変えたら、両方を直す。
  test('サーバーと同じく、NFKC で表記の揺れをそろえる', () {
    const examples = {
      'ＲＥＩ　ｶﾞｷﾞﾐﾅﾄ': 'rei がぎみなと',
      '￥１００': '¥100',
      '①': '1',
      'Ⅱ': 'ii',
      '㈱': '(株)',
      'x²': 'x2',
      'が': 'が', // 結合文字の濁点
      'か゛': 'か ゙', // 単独の濁点は、まとめない
      'ｳﾞｧｲｵﾘﾝ': 'ゔぁいおりん',
      'ヴヵヶ': 'ゔゕゖ',
      'ヷ': 'ヷ', // ひらがなにない字は、カタカナのまま
      'Café': 'café',
      'ﾐﾅﾄ｡': 'みなと。',
    };
    for (final MapEntry(:key, :value) in examples.entries) {
      expect(normalizeForSearch(key), value, reason: key);
    }
  });
}
