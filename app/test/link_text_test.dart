import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/ui/link_text.dart';

void main() {
  group('splitLinks', () {
    test('URL とそれ以外に分け、末尾の句読点や閉じかっこは URL に含めない', () {
      final parts = splitLinks(
        '見てね https://example.com/a?b=1。（https://x.com/p）',
      );
      expect(parts.map((p) => p.text).toList(), [
        '見てね ',
        'https://example.com/a?b=1',
        '。（',
        'https://x.com/p',
        '）',
      ]);
      expect(parts[1].url, Uri.parse('https://example.com/a?b=1'));
      expect(parts[0].url, isNull);
    });

    test('https:// のない URL もリンクにする。メールアドレスは拾わない', () {
      final parts = splitLinks('動画 youtu.be/abcDEF12345\n連絡 a@example.com/x');
      expect(parts[1].text, 'youtu.be/abcDEF12345');
      expect(parts[1].url, Uri.parse('https://youtu.be/abcDEF12345'));
      expect(parts[1].truncated, isFalse);
      expect(parts.where((p) => p.url != null), hasLength(1));
    });

    test('… で切れた URL は、… まで含めて、切れたものとして分ける', () {
      final parts = splitLinks('来るぞ！ x.com/minato_ch/stat… またね');
      expect(parts.map((p) => p.text).toList(), [
        '来るぞ！ ',
        'x.com/minato_ch/stat…',
        ' またね',
      ]);
      expect(parts[1].truncated, isTrue);
    });

    test('URL がなければ、そのまま1つ', () {
      expect(splitLinks('こんにちは').single.text, 'こんにちは');
      expect(splitLinks(''), isEmpty);
    });
  });

  test('shortenUrl は https:// と www. を省き、長ければ切る', () {
    expect(shortenUrl('https://www.example.com/a'), 'example.com/a');
    expect(
      shortenUrl('https://example.com/abcdefghijklmnopqrstuvwxyz0123'),
      'example.com/abcdefghijklmnopq…',
    );
  });

  group('splitXEntities', () {
    test('@ユーザー名は X のプロフィールへ、#ハッシュタグは X の検索へ結ぶ', () {
      final parts = splitXEntities(
        splitLinks('@hiyori_x と #推し活 の話 https://example.com/a'),
      );
      final mention = parts.firstWhere((p) => p.text == '@hiyori_x');
      expect(mention.url, Uri.parse('https://x.com/hiyori_x'));
      expect(mention.entity, isTrue);
      final tag = parts.firstWhere((p) => p.text == '#推し活');
      expect(tag.url!.host, 'x.com');
      expect(tag.url!.path, '/search');
      expect(tag.url!.queryParameters['q'], '#推し活');
      expect(
        parts.firstWhere((p) => p.text == 'https://example.com/a').entity,
        isFalse,
      );
    });

    test('メールアドレスや、URL の中の # は拾わない', () {
      final parts = splitXEntities(
        splitLinks('連絡 a@example.com と https://example.com/#top'),
      );
      expect(parts.where((p) => p.entity), isEmpty);
    });
  });
}
