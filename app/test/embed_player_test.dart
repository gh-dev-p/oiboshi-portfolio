import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/ui/embed_player.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import 'fakes.dart';

const _youtube = 'https://www.youtube.com/embed/abc?start=12';
const _twitch = 'https://player.twitch.tv/?channel=minato';

void main() {
  group('埋め込みプレイヤーのページ', () {
    test('YouTube の生配信は、再生位置を分からない（-1）とする（位置から始めると再生できないため）', () {
      final youtube = embedHtml(_youtube);
      expect(youtube, contains('if (data && data.isLive) return -1;'));
      expect(youtube, contains('return player.getCurrentTime();'));
      expect(youtube, contains('start: 12'));
    });

    test('音を消す状態なら、音を消して始める', () {
      final youtube = embedHtml(_youtube, audioSuppressed: true);
      expect(youtube, contains('var suppressed = true;'));
      expect(youtube, contains('mute: 1'));
      final twitch = embedHtml(_twitch, audioSuppressed: true);
      expect(twitch, contains('var suppressed = true;'));
      expect(twitch, contains('muted: suppressed'));
    });

    test('前の動画が終わって音を戻すとき、止められていた配信を流し直す（iOS は後ろの映像を止めることがある）', () {
      final twitch = embedHtml(_twitch);
      expect(twitch, contains('if (player.isPaused()) player.play();'));
      final youtube = embedHtml(_youtube);
      expect(youtube, contains('if (player.getPlayerState() !== 1) {'));
      // 配信なら、遅れたぶん、いちばん新しい位置まで進める。
      expect(
        youtube,
        contains(
          'if (data && data.isLive) player.seekTo(player.getDuration(), true);',
        ),
      );
    });

    test('ページの JS では再生を命令せず、準備ができたらアプリに知らせる（低電力モードでは、ページの JS からの再生は止められる）', () {
      final twitch = embedHtml(_twitch);
      expect(twitch, contains('postMessage("ready")'));
      expect(
        twitch,
        contains('window.startPlayback = function () { player.play(); };'),
      );
      expect(
        twitch,
        contains(
          'if (playing) return;\n    if (player.isPaused()) player.play();',
        ),
      );
      expect(twitch, isNot(contains('setInterval')));
      // ミュートは見回らない（ユーザーのミュートを外さない）。
      expect(twitch, isNot(contains('getMuted()) player.setMuted(false)')));
      final youtube = embedHtml(_youtube);
      expect(youtube, contains('postMessage("ready")'));
      expect(
        youtube,
        contains('window.startPlayback = function () { player.playVideo(); };'),
      );
      expect(
        youtube,
        contains(
          'if (played) return;\n    if (player.getPlayerState() !== 3) player.playVideo();',
        ),
      );
      expect(youtube, isNot(contains('setInterval')));
    });

    test('Twitch が自分でミュートにして始めたら、音を消す理由がなければ、アプリに知らせる（1回だけ）', () {
      final twitch = embedHtml(_twitch);
      expect(
        twitch,
        contains(
          'if (autoMutedSent || suppressed || !player.getMuted()) return;',
        ),
      );
      expect(twitch, contains('postMessage("autoMuted")'));
      expect(twitch, contains('setTimeout(checkAutoMuted, 2000);'));
    });

    test('YouTube は、ミュートを見回らない', () {
      final youtube = embedHtml(_youtube);
      // 再生し直す見回りはあるが、ミュートには触らない。
      expect(youtube, isNot(contains('isMuted()) player.unMute()')));
    });

    test('ふだんは、音を出して始める', () {
      final youtube = embedHtml(_youtube);
      expect(youtube, contains('var suppressed = false;'));
      expect(youtube, contains('mute: 0'));
      expect(embedHtml(_twitch), contains('var suppressed = false;'));
    });

    test('プレイヤーを読み込めない・エラー・準備ができないまま時間が過ぎたら、再生できないと知らせる', () {
      for (final html in [embedHtml(_youtube), embedHtml(_twitch)]) {
        expect(html, contains('onerror="notifyFailed()"'));
        expect(html, contains('OiboshiPlayer.postMessage("failed")'));
        expect(html, contains('if (!ready) notifyFailed();'));
        // 知らせる関数は、公式の JavaScript API の読み込みより前に置く。
        expect(
          html.indexOf('function notifyFailed'),
          lessThan(html.indexOf('onerror="notifyFailed()"')),
        );
      }
      expect(
        embedHtml(_youtube),
        contains('onError: function () { notifyStarted(); notifyFailed(); }'),
      );
    });

    test('準備の前に受けた命令は覚えておき、準備ができたときに当てる', () {
      for (final html in [embedHtml(_youtube), embedHtml(_twitch)]) {
        expect(html, contains('suppressed = on;\n    if (!ready) return;'));
        expect(html, contains('ready = true;'));
      }
    });
  });

  group('埋め込みプレイヤー', () {
    setUp(() {
      WebViewPlatform.instance = FakeWebViewPlatform();
      FakeWebViewPlatform.loadedHtml.clear();
      FakeWebViewPlatform.loadedBaseUrls.clear();
      FakeWebViewPlatform.scripts.clear();
      FakeWebViewPlatform.pageFinished.clear();
      FakeWebViewPlatform.channels.clear();
    });

    Widget player(String url, {required bool audioSuppressed}) =>
        Directionality(
          textDirection: TextDirection.ltr,
          child: EmbedPlayer(url: url, audioSuppressed: audioSuppressed),
        );

    testWidgets('外したら、空のページを読み込んで止める（WebView は外してもすぐには消えず、Twitch は隠れても止まらない）', (
      tester,
    ) async {
      await tester.pumpWidget(player(_twitch, audioSuppressed: false));
      expect(FakeWebViewPlatform.loadedHtml.last, contains('Twitch.Player'));
      await tester.pumpWidget(const SizedBox());
      expect(FakeWebViewPlatform.loadedHtml.last, isNot(contains('<script')));
      expect(
        FakeWebViewPlatform.loadedHtml.last,
        contains('<body style="background:#000"></body>'),
      );
    });

    testWidgets('土台の URL をアプリ ID にし、Twitch の parent も同じホストにする', (tester) async {
      await tester.pumpWidget(player(_youtube, audioSuppressed: false));
      expect(
        FakeWebViewPlatform.loadedBaseUrls.last,
        'https://com.example.oiboshi',
      );
      await tester.pumpWidget(player(_twitch, audioSuppressed: false));
      expect(
        FakeWebViewPlatform.loadedBaseUrls.last,
        'https://com.example.oiboshi',
      );
      expect(
        FakeWebViewPlatform.loadedHtml.last,
        contains('parent: ["com.example.oiboshi"]'),
      );
    });

    testWidgets('作った時点の消音を、ページに埋め込み、読み込み終えたら当て直す', (tester) async {
      await tester.pumpWidget(player(_youtube, audioSuppressed: true));
      expect(FakeWebViewPlatform.loadedHtml.last, contains('mute: 1'));
      FakeWebViewPlatform.pageFinished.last(embedBaseUrl);
      expect(
        FakeWebViewPlatform.scripts.last,
        contains('window.suppressAudio(true)'),
      );
    });

    testWidgets('URL が替わって読み込み直すときも、いまの消音を埋め込む', (tester) async {
      await tester.pumpWidget(player(_youtube, audioSuppressed: true));
      await tester.pumpWidget(player(_twitch, audioSuppressed: true));
      expect(FakeWebViewPlatform.loadedHtml.last, contains('channel'));
      expect(
        FakeWebViewPlatform.loadedHtml.last,
        contains('var suppressed = true;'),
      );
    });

    testWidgets('準備ができたら、アプリから再生を命令し、20秒の間、2秒ごとに命令し直す', (tester) async {
      await tester.pumpWidget(player(_twitch, audioSuppressed: false));
      FakeWebViewPlatform.channels.last.onMessageReceived(
        const JavaScriptMessage(message: 'ready'),
      );
      expect(
        FakeWebViewPlatform.scripts.last,
        'window.startPlayback && window.startPlayback()',
      );
      bool isRetry(String script) => script.contains('window.retryPlayback()');
      await tester.pump(const Duration(seconds: 2));
      expect(FakeWebViewPlatform.scripts.where(isRetry), hasLength(1));
      await tester.pump(const Duration(seconds: 30));
      expect(FakeWebViewPlatform.scripts.where(isRetry), hasLength(10));
    });

    testWidgets('読み込み直したら、前のページへの命令し直しをやめる', (tester) async {
      await tester.pumpWidget(player(_youtube, audioSuppressed: false));
      FakeWebViewPlatform.channels.last.onMessageReceived(
        const JavaScriptMessage(message: 'ready'),
      );
      await tester.pumpWidget(player(_twitch, audioSuppressed: false));
      await tester.pump(const Duration(seconds: 30));
      expect(
        FakeWebViewPlatform.scripts.where(
          (script) => script.contains('window.retryPlayback()'),
        ),
        isEmpty,
      );
    });

    testWidgets('消音が切り替わったら、プレイヤーに命令する', (tester) async {
      await tester.pumpWidget(player(_youtube, audioSuppressed: true));
      await tester.pumpWidget(player(_youtube, audioSuppressed: false));
      expect(
        FakeWebViewPlatform.scripts.last,
        contains('window.suppressAudio(false)'),
      );
    });
  });
}
