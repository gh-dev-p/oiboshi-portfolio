import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/sns_account_input.dart';
import 'package:oiboshi/domain/models/sns_service.dart';

/// 追いたいの、SNS の URL・ID の読み取り（機能仕様書（届ける・広める）4.5.1）。
/// そろえた形は、サーバーの `private.want_account_valid`（supabase/tests/database/wants.test.sql）と合わせる。
void main() {
  SnsAccountInput? parse(String input, [SnsService? service]) =>
      SnsAccountInput.parse(input, service: service);

  void expectParsed(
    String input,
    SnsService service,
    String account, {
    SnsService? given,
  }) {
    expect(
      parse(input, given),
      SnsAccountInput(service, account),
      reason: input,
    );
  }

  void expectNull(String input, [SnsService? given]) {
    expect(parse(input, given), isNull, reason: input);
  }

  group('YouTube', () {
    const channel = 'UCabcdefghijklmnopqrstuV';

    test('ハンドルの URL', () {
      for (final input in [
        'https://www.youtube.com/@ReiCh',
        'http://youtube.com/@reich',
        'youtube.com/@ReiCh',
        'www.youtube.com/@ReiCh/videos',
        'https://m.youtube.com/@ReiCh/streams?si=abc#x',
        'HTTPS://WWW.YOUTUBE.COM/@ReiCh',
        'https://www.youtube.com./@ReiCh',
        '  https://www.youtube.com/@ReiCh  ',
      ]) {
        expectParsed(input, SnsService.youtube, '@reich');
      }
    });

    test('英字以外のハンドル（% で書いた URL も読む）', () {
      expectParsed(
        'https://www.youtube.com/@みなとちゃんねる',
        SnsService.youtube,
        '@みなとちゃんねる',
      );
      expectParsed(
        'https://www.youtube.com/@%E3%81%BF%E3%81%AA%E3%81%A8ch',
        SnsService.youtube,
        '@みなとch',
      );
      expectParsed(
        'youtube.com/@rei.ch-1_2',
        SnsService.youtube,
        '@rei.ch-1_2',
      );
    });

    test('チャンネル ID の URL（大文字・小文字はそのまま）', () {
      expectParsed(
        'https://www.youtube.com/channel/$channel',
        SnsService.youtube,
        channel,
      );
      expectParsed(
        'youtube.com/channel/$channel/live',
        SnsService.youtube,
        channel,
      );
    });

    test('ID だけ', () {
      expectParsed(
        '@ReiCh',
        SnsService.youtube,
        '@reich',
        given: SnsService.youtube,
      );
      expectParsed(
        'ReiCh',
        SnsService.youtube,
        '@reich',
        given: SnsService.youtube,
      );
      expectParsed(
        '＠ReiCh',
        SnsService.youtube,
        '@reich',
        given: SnsService.youtube,
      );
      expectParsed(
        channel,
        SnsService.youtube,
        channel,
        given: SnsService.youtube,
      );
    });

    test('チャンネルが決まらない URL は読まない', () {
      for (final input in [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/dQw4w9WgXcQ',
        'https://www.youtube.com/c/ReiChannel',
        'https://www.youtube.com/user/reichannel',
        'https://www.youtube.com/ReiChannel',
        'https://www.youtube.com/shorts/abc',
        'https://www.youtube.com/',
        'https://www.youtube.com/channel/',
        'https://www.youtube.com/channel/UCshort',
        'https://music.youtube.com/@ReiCh',
      ]) {
        expectNull(input);
      }
    });

    test('ハンドルの長さと文字', () {
      expectNull('@ab', SnsService.youtube);
      expectParsed(
        'abc',
        SnsService.youtube,
        '@abc',
        given: SnsService.youtube,
      );
      expectParsed(
        'a' * 30,
        SnsService.youtube,
        '@${'a' * 30}',
        given: SnsService.youtube,
      );
      expectNull('a' * 31, SnsService.youtube);
      expectNull('rei!ch', SnsService.youtube);
      expectNull('@@reich', SnsService.youtube);
    });
  });

  group('X', () {
    test('URL', () {
      for (final input in [
        'https://x.com/Rei_Tsuki',
        'https://twitter.com/rei_tsuki',
        'https://mobile.twitter.com/Rei_Tsuki',
        'https://www.x.com/Rei_Tsuki/',
        'x.com/Rei_Tsuki/status/1234567890?s=20',
        'https://x.com/rei_tsuki/media',
      ]) {
        expectParsed(input, SnsService.x, 'rei_tsuki');
      }
    });

    test('ID だけ', () {
      expectParsed(
        '@Rei_Tsuki',
        SnsService.x,
        'rei_tsuki',
        given: SnsService.x,
      );
      expectParsed('rei_tsuki', SnsService.x, 'rei_tsuki', given: SnsService.x);
      expectParsed('a', SnsService.x, 'a', given: SnsService.x);
    });

    test('アカウントのページでない URL は読まない', () {
      for (final input in [
        'https://x.com/home',
        'https://x.com/explore',
        'https://x.com/search?q=rei',
        'https://x.com/i/lists/123',
        'https://x.com/hashtag/oiboshi',
        'https://twitter.com/intent/tweet?text=a',
        'https://x.com/settings/profile',
        'https://x.com/',
      ]) {
        expectNull(input);
      }
    });

    test('形が違う', () {
      expectNull('a' * 16, SnsService.x);
      expectNull('rei-tsuki', SnsService.x);
      expectNull('rei.tsuki', SnsService.x);
      expectNull('https://x.com/rei-tsuki');
    });
  });

  group('Instagram', () {
    test('URL', () {
      for (final input in [
        'https://www.instagram.com/Rei.Tsuki_/',
        'instagram.com/rei.tsuki_',
        'https://instagram.com/rei.tsuki_?igsh=abc',
        'https://www.instagram.com/rei.tsuki_/reels/',
        'https://www.instagram.com/stories/rei.tsuki_/123456/',
      ]) {
        expectParsed(input, SnsService.instagram, 'rei.tsuki_');
      }
    });

    test('ID だけ（. を含んでも URL と見ない）', () {
      expectParsed(
        'rei.tsuki_',
        SnsService.instagram,
        'rei.tsuki_',
        given: SnsService.instagram,
      );
      expectParsed(
        '@Rei.Tsuki_',
        SnsService.instagram,
        'rei.tsuki_',
        given: SnsService.instagram,
      );
    });

    test('アカウントのページでない URL は読まない', () {
      for (final input in [
        'https://www.instagram.com/p/Cabc123/',
        'https://www.instagram.com/reel/Cabc123/',
        'https://www.instagram.com/explore/tags/a/',
        'https://www.instagram.com/accounts/login/',
        'https://www.instagram.com/stories/',
      ]) {
        expectNull(input);
      }
    });

    test('形が違う', () {
      expectNull('rei-tsuki', SnsService.instagram);
      expectNull('a' * 31, SnsService.instagram);
    });
  });

  group('Twitch', () {
    test('URL', () {
      for (final input in [
        'https://www.twitch.tv/Rei_TV',
        'twitch.tv/rei_tv',
        'https://m.twitch.tv/rei_tv/videos',
        'https://www.twitch.tv/rei_tv/clip/AbcDef',
        'https://www.twitch.tv/rei_tv?sr=a',
      ]) {
        expectParsed(input, SnsService.twitch, 'rei_tv');
      }
    });

    test('ID だけ', () {
      expectParsed(
        'Rei_TV',
        SnsService.twitch,
        'rei_tv',
        given: SnsService.twitch,
      );
    });

    test('アカウントのページでない URL は読まない', () {
      for (final input in [
        'https://www.twitch.tv/directory/category/just-chatting',
        'https://www.twitch.tv/videos/123456',
        'https://www.twitch.tv/settings/profile',
        'https://clips.twitch.tv/AbcDef',
        'https://www.twitch.tv/',
      ]) {
        expectNull(input);
      }
    });

    test('形が違う', () {
      expectNull('ab', SnsService.twitch);
      expectNull('a' * 26, SnsService.twitch);
      expectNull('rei-tv', SnsService.twitch);
    });
  });

  group('ツイキャス', () {
    test('URL', () {
      expectParsed(
        'https://twitcasting.tv/Rei_Cas',
        SnsService.twitcasting,
        'rei_cas',
      );
      expectParsed(
        'twitcasting.tv/c:rei_cas/movie/123',
        SnsService.twitcasting,
        'c:rei_cas',
      );
      expectNull('https://twitcasting.tv/indexpage.php');
      expectNull('https://twitcasting.tv/');
    });

    test('ID だけ（: を含んでも URL と見ない）', () {
      expectParsed(
        'c:rei_cas',
        SnsService.twitcasting,
        'c:rei_cas',
        given: SnsService.twitcasting,
      );
      expectParsed(
        'g:123456',
        SnsService.twitcasting,
        'g:123456',
        given: SnsService.twitcasting,
      );
    });
  });

  group('共通', () {
    test('ID だけで SNS が分からなければ読まない', () {
      expectNull('rei_tsuki');
      expectNull('@rei_tsuki');
    });

    test('URL の SNS と、選んだ SNS が違えば読まない', () {
      expectNull('https://x.com/rei_tsuki', SnsService.twitch);
      expectParsed(
        'https://x.com/rei_tsuki',
        SnsService.x,
        'rei_tsuki',
        given: SnsService.x,
      );
    });

    test('追星が扱わない SNS・URL でない文字は読まない', () {
      for (final input in [
        '',
        '   ',
        'https://www.tiktok.com/@rei',
        'https://example.com/rei',
        'https://x.com.example.com/rei',
        'ftp://x.com/rei',
        'javascript:alert(1)',
        'rei tsuki',
      ]) {
        expectNull(input);
        expectNull(input, SnsService.x);
      }
    });

    test('ID だけのときに / を含めば読まない', () {
      expectNull('rei/tsuki', SnsService.x);
    });

    test('壊れた % の書き方は読まない', () {
      expectNull('https://www.youtube.com/@%E3%81');
    });
  });
}
