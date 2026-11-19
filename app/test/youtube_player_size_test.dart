import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/post/widgets/post_viewer_parts.dart';

void main() {
  group('投稿ビューアの YouTube のプレイヤーの大きさ（規約の最小 200×200）', () {
    test('横長は、幅いっぱいに縦横比のまま置く', () {
      expect(
        youtubePlayerSize(const Size(400, 300), 16 / 9),
        const Size(400, 225),
      );
    });

    test('縦長で幅が 200 に足りなければ、幅を 200 に広げる（左右は黒）', () {
      expect(
        youtubePlayerSize(const Size(400, 266), 9 / 16),
        const Size(200, 266),
      );
    });

    test('高さが 200 に足りなければ、流さない（null。サムネイルだけ出す）', () {
      expect(youtubePlayerSize(const Size(400, 150), 16 / 9), isNull);
      expect(youtubePlayerSize(const Size(400, 199), 9 / 16), isNull);
    });
  });
}
