import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../utils/open_url.dart';

/// 埋め込み元のページのホスト名。アプリ ID（逆ドメイン、小文字）にする。
/// YouTube は、WebView のアプリに `https://` ＋アプリ ID の `Referer` で名乗ることを求める（Required Minimum Functionality の API Client Identity）。
/// `Referer` は、土台のページの URL（[embedBaseUrl]）から付く。
/// Twitch は、プレイヤーの `parent` と同じホストのページからしか再生を許さないので、`parent` にも同じホストを渡す。
/// サーバーの twitch.ts が `lives.playback_url` に入れる `parent` は使わない（チャンネル名だけ読む）。
const embedBaseHost = 'com.example.oiboshi';

/// 埋め込み元のページの URL。
const embedBaseUrl = 'https://$embedBaseHost';

/// プレイヤーのページから、アプリへ知らせる窓口の名前。
const _channel = 'OiboshiPlayer';

/// 公式プレイヤー（YouTube・Twitch）を WebView に埋め込み、音を出して自動再生する。
/// ミュートの解除は、公式プレイヤーの音量の操作で行う。
/// 前で別の動画が音を出している間（[audioSuppressed]）は、音を消し、終わったら元に戻す。
/// 作った時点・URL が替わって読み込み直した時点で音を消す状態なら、音を消して始める。
/// 準備ができたらページがアプリに知らせ、アプリが `runJavaScript` で再生を命令する。アプリが前面に戻ったときも再生し直す。
/// iOS の低電力モードでは、WebKit が、ユーザーの操作なしの動画の再生を止める（音なしでも）。
/// `runJavaScript`（WKWebView の `evaluateJavaScript`）は、操作の印を付けて動くので、ページの JS からではなく、
/// アプリから命令する（tech-risks 2.33）。
/// Twitch が自分でミュートにして始めたら（音ありの再生が通らなかった）、ユーザーがプレイヤーに触っていなければ、
/// 1回だけページを読み込み直して、音ありの再生をやり直させる。
/// プレイヤーの中のリンク（タイトルやロゴ）は、WebView の中で開かず、外のアプリで開く。
class EmbedPlayer extends StatefulWidget {
  const EmbedPlayer({
    super.key,
    required this.url,
    this.audioSuppressed = false,
    this.onStarted,
    this.onPlaying,
    this.onFailed,
    this.onEnded,
    this.onPaused,
    this.handle,
  });

  /// プレイヤーの URL（`lives.playback_url`）。YouTube は `?start={秒}` で、始める位置を渡せる。
  final String url;

  /// 前で別の動画が音を出しているか。最初の状態はページに埋め込み、切り替わると、プレイヤーに命令する。
  final bool audioSuppressed;

  /// 映像が出始めたとき（再生が始まった、または再生できないと分かった）。YouTube だけ知らせる。
  final VoidCallback? onStarted;

  /// 再生が始まったとき（再生できないときは呼ばない。[onStarted] と違う）。YouTube だけ知らせる。
  final VoidCallback? onPlaying;

  /// 再生できないと分かったとき（プレイヤーの読み込みの失敗、YouTube のエラー、準備ができないまま時間が過ぎた）。
  /// YouTube・Twitch で知らせる。
  final VoidCallback? onFailed;

  /// 最後まで再生したとき。YouTube だけ知らせる。
  final VoidCallback? onEnded;

  /// 一時停止したとき（ユーザーがプレイヤーで止めた）。YouTube だけ知らせる。
  final VoidCallback? onPaused;

  /// いまの再生位置を、外から聞くための窓口。YouTube だけ答える。
  final EmbedPlayerHandle? handle;

  @override
  State<EmbedPlayer> createState() => _EmbedPlayerState();
}

class _EmbedPlayerState extends State<EmbedPlayer> with WidgetsBindingObserver {
  late final WebViewController _controller;

  /// ユーザーがプレイヤーに触ったか。触っていたら、ミュートはユーザーのものとみなし、読み込み直さない。
  bool _touched = false;

  /// Twitch が自分でミュートにしたので、読み込み直したか。読み込み直すのは1回だけ。
  bool _reloadedForSound = false;

  /// 準備ができたあと、再生が始まるまで、再生を命令し直すタイマー。
  Timer? _retryTimer;

  /// 再生を命令し直す間隔と回数（20秒の間、2秒ごと）。
  static const _retryInterval = Duration(seconds: 2);
  static const _maxRetries = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _createController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        _channel,
        onMessageReceived: (message) {
          switch (message.message) {
            case 'started':
              widget.onStarted?.call();
            case 'playing':
              widget.onPlaying?.call();
            case 'failed':
              widget.onFailed?.call();
            case 'ended':
              widget.onEnded?.call();
            case 'paused':
              widget.onPaused?.call();
            case 'autoMuted':
              _reloadForSound();
            case 'ready':
              _startPlayback();
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // 読み込みの途中で切り替わった命令は、ページが受け取れずに消えるので、読み込み終えたら当て直す。
          onPageFinished: (_) => _applyAudioSuppressed(),
          onNavigationRequest: (request) {
            // 最初の読み込み（土台のページ）と、プレイヤー自身（iframe の中）は通す。
            if (!request.isMainFrame || request.url.startsWith(embedBaseUrl)) {
              return NavigationDecision.navigate;
            }
            openUrl(Uri.parse(request.url));
            return NavigationDecision.prevent;
          },
        ),
      );
    _load();
    widget.handle?._attach(this);
  }

  @override
  void didUpdateWidget(EmbedPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle != widget.handle) {
      oldWidget.handle?._detach(this);
      widget.handle?._attach(this);
    }
    if (oldWidget.url != widget.url) {
      _touched = false;
      _reloadedForSound = false;
      _load();
    }
    if (oldWidget.audioSuppressed != widget.audioSuppressed) {
      _applyAudioSuppressed();
    }
  }

  /// いまの [EmbedPlayer.audioSuppressed] を、プレイヤーに当てる。同じ状態を当て直しても、何も変えない。
  void _applyAudioSuppressed() {
    if (!mounted) return;
    _controller.runJavaScript(
      'window.suppressAudio && window.suppressAudio(${widget.audioSuppressed})',
    );
  }

  /// プレイヤーの準備ができたら、再生を命令する。
  /// 作った直後に画面に出ていないと判断されると、自動再生が止められることがあるので、
  /// 受動的に流し続けるため、一度も再生が始まっていなければ、[_maxRetries] 回、[_retryInterval] ごとに命令し直す。
  /// 始まったかは、ページが見る（始まったあとは、命令し直しても何もしない。ユーザーが止めたのを、こちらで動かさない）。
  void _startPlayback() {
    if (!mounted) return;
    _retryTimer?.cancel();
    _controller.runJavaScript('window.startPlayback && window.startPlayback()');
    var tries = 0;
    _retryTimer = Timer.periodic(_retryInterval, (timer) {
      if (!mounted || ++tries > _maxRetries) {
        timer.cancel();
        return;
      }
      _controller.runJavaScript(
        'window.retryPlayback && window.retryPlayback()',
      );
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    widget.handle?._detach(this);
    WidgetsBinding.instance.removeObserver(this);
    // 画面から外しても、WebView（WKWebView）はすぐには消えず、Twitch のプレイヤーは隠れても自分では止まらない
    // （投稿ビューアを開いて固定ビューアの Twitch を外したとき、裏で流れ続けた）。空のページを読み込んで、確実に止める。
    _controller.loadHtmlString(_blankHtml, baseUrl: embedBaseUrl);
    super.dispose();
  }

  /// いまの再生位置。分からなければ null。
  Future<Duration?> _position() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'window.currentTime ? window.currentTime() : -1',
      );
      final seconds = double.tryParse(result.toString());
      if (seconds == null || seconds < 0) return null;
      return Duration(milliseconds: (seconds * 1000).round());
    } catch (_) {
      return null;
    }
  }

  /// 動画の長さ。分からない（準備の前・生配信）なら null。YouTube だけ答える。
  Future<Duration?> _duration() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        'window.videoDuration ? window.videoDuration() : -1',
      );
      final seconds = double.tryParse(result.toString());
      if (seconds == null || seconds <= 0) return null;
      return Duration(milliseconds: (seconds * 1000).round());
    } catch (_) {
      return null;
    }
  }

  /// 再生位置を [position] に動かす。[play] なら、止まっていても再生する。YouTube だけ動く。
  void _seek(Duration position, {required bool play}) {
    if (!mounted) return;
    final seconds = (position.inMilliseconds / 1000).toStringAsFixed(1);
    _controller.runJavaScript(
      'window.seekVideo && window.seekVideo($seconds, $play)',
    );
  }

  /// バックグラウンドに行くとプレイヤーが止まるので、戻ってきたら再生し直す。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.runJavaScript(
        'window.resumePlayback && window.resumePlayback()',
      );
    }
  }

  /// Twitch が自分でミュートにして始めたとき。ユーザーが触っておらず、まだなら、1回だけ読み込み直す。
  /// Twitch は一度ミュートにすると、命令ではミュートを外せないので、作り直して音ありの再生をやり直させる。
  /// それでもミュートになったら、ミュートのまま流す。
  void _reloadForSound() {
    if (!mounted || _touched || _reloadedForSound) return;
    _reloadedForSound = true;
    _load();
  }

  void _load() {
    _retryTimer?.cancel();
    _controller.loadHtmlString(
      embedHtml(widget.url, audioSuppressed: widget.audioSuppressed),
      baseUrl: embedBaseUrl,
    );
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _touched = true,
    child: WebViewWidget(controller: _controller),
  );
}

/// [EmbedPlayer] に、いまの再生位置を聞く窓口。プレイヤーを作る側が持ち、[EmbedPlayer.handle] に渡す。
class EmbedPlayerHandle {
  _EmbedPlayerState? _state;

  void _attach(_EmbedPlayerState state) => _state = state;

  void _detach(_EmbedPlayerState state) {
    if (_state == state) _state = null;
  }

  /// いまの再生位置。プレイヤーがない・分からなければ null。
  Future<Duration?> position() async => _state?._position();

  /// 動画の長さ。プレイヤーがない・分からない（生配信など）なら null。YouTube だけ答える。
  Future<Duration?> duration() async => _state?._duration();

  /// 再生位置を [position] に動かす（固定ビューアのコントローラーの早送り・巻き戻し）。
  /// [play] なら、止まっていても再生する。プレイヤーがなければ何もしない。YouTube だけ動く。
  void seek(Duration position, {bool play = false}) =>
      _state?._seek(position, play: play);
}

/// 音声つきの自動再生を、ユーザーの操作なしで許す設定にして作る。
WebViewController _createController() {
  final PlatformWebViewControllerCreationParams params;
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }
  final controller = WebViewController.fromPlatformCreationParams(params);
  if (controller.platform case final AndroidWebViewController android) {
    android.setMediaPlaybackRequiresUserGesture(false);
  }
  return controller;
}

/// プレイヤーを外したときに読み込む、空のページ（流していたものを止める）。
const _blankHtml =
    '<!doctype html><html><body style="background:#000"></body></html>';

/// プレイヤーを画面いっぱいに置くページ。
/// Twitch・YouTube は、公式の JavaScript API で作り、準備ができたら、音を出して再生を命令する。
/// [audioSuppressed] なら、音を消して始め、`window.suppressAudio(false)` で音を出す。
/// 準備の前に受けた `window.suppressAudio` は覚えておき、準備ができたときに当てる。
/// 知らない URL は、iframe にそのまま入れる。
String embedHtml(String playerUrl, {bool audioSuppressed = false}) {
  final url = Uri.tryParse(playerUrl);
  if (url != null) {
    if (url.host == 'player.twitch.tv') {
      final channel = url.queryParameters['channel'];
      if (channel != null && channel.isNotEmpty) {
        return _twitchHtml(channel, audioSuppressed: audioSuppressed);
      }
    }
    if (url.host.endsWith('youtube.com') &&
        url.pathSegments.length >= 2 &&
        url.pathSegments.first == 'embed') {
      final start = int.tryParse(url.queryParameters['start'] ?? '') ?? 0;
      return _youtubeHtml(
        url.pathSegments[1],
        start: start,
        audioSuppressed: audioSuppressed,
      );
    }
  }
  return _iframeHtml(playerUrl);
}

const _style = '''
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; height: 100%; background: #000; overflow: hidden; }
  #player, #player iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
</style>
''';

/// 準備ができたか（`ready`）と、再生できないと分かったときにアプリへ知らせる関数（`notifyFailed`）。
/// 公式の JavaScript API の読み込みより前に置く（読み込みの失敗を、`onerror` で知らせるため）。
/// 準備ができないまま [_readyTimeout] が過ぎたら、再生できないとみなす。
String get _failScript =>
    '''
<script>
  var ready = false;
  var failed = false;
  function notifyFailed() {
    if (failed) return;
    failed = true;
    if (window.$_channel) $_channel.postMessage("failed");
  }
  setTimeout(function () { if (!ready) notifyFailed(); }, ${_readyTimeout.inMilliseconds});
</script>
''';

/// 公式プレイヤーの準備を待つ長さ。
const _readyTimeout = Duration(seconds: 20);

/// JavaScript の文字列として埋め込める形にする。`</script>` で閉じられないように `<` も置き換える。
String _js(String value) => jsonEncode(value).replaceAll('<', r'\u003c');

/// Twitch のプレイヤーを組み立てる、仮の大きさの下限（CSS ピクセル）。
/// Twitch は、狭い幅では、配信者の名前・タイトル・フォローの帯や操作を、幅に対して大きく出す
/// （スマホの幅 390×219 では、帯が右にはみ出し、タイトルが映像の上半分を覆った）。
/// 埋め込みの決まり（幅 400・高さ 300 以上）を満たす 640×360 以上で組み立て、WebView の大きさに縮めて見せる。
/// 縮めるだけで、ロゴや操作は隠さない。
const twitchMinWidth = 640;
const twitchMinHeight = 360;

/// プレイヤーの箱（`#player`）を、[twitchMinWidth]×[twitchMinHeight] 以上の仮の大きさで組み立て、
/// WebView の大きさに縮める。WebView の縦横比は変えない。WebView が大きさを変えたら、組み立て直す。
const _twitchFitScript =
    '''
<script>
  (function () {
    var box = document.getElementById("player");
    function fit() {
      var w = window.innerWidth, h = window.innerHeight;
      if (!w || !h) return;
      var s = Math.min(1, w / $twitchMinWidth, h / $twitchMinHeight);
      box.style.transformOrigin = "0 0";
      box.style.width = (w / s) + "px";
      box.style.height = (h / s) + "px";
      box.style.transform = s < 1 ? "scale(" + s + ")" : "";
    }
    fit();
    window.addEventListener("resize", fit);
  })();
</script>
''';

String _twitchHtml(String channel, {required bool audioSuppressed}) =>
    '''
<!doctype html>
<html>
<head>
$_style
</head>
<body>
<div id="player"></div>
$_failScript
<script src="https://embed.twitch.tv/embed/v1.js" onerror="notifyFailed()"></script>
$_twitchFitScript
<script>
  // 前で別の動画が音を出しているか。準備ができるまでは、ここに覚えておく。
  var suppressed = $audioSuppressed;
  var mutedBefore = null;
  var player = new Twitch.Player("player", {
    channel: ${_js(channel)},
    parent: [${_js(embedBaseHost)}],
    autoplay: true,
    muted: suppressed,
    width: "100%",
    height: "100%"
  });
  player.addEventListener(Twitch.Player.READY, function () {
    ready = true;
    // 音を消している間は、消したまま始め、前の動画が終わったら音を出す。
    player.setMuted(suppressed);
    if (suppressed) mutedBefore = false;
    // 再生は、アプリが命令する（低電力モードでは、ページの JS からの再生は止められる）。
    if (window.$_channel) $_channel.postMessage("ready");
  });
  // アプリから呼ぶ。準備ができたときの再生。
  window.startPlayback = function () { player.play(); };
  // アプリから呼ぶ。一度も再生が始まっていなければ、再生し直す。始まったあとは何もしない。
  window.retryPlayback = function () {
    if (playing) return;
    if (player.isPaused()) player.play();
  };
  // 音ありの再生が通らないと、Twitch は自分でミュートにして流し直し、そのあとは命令でミュートを外せない。
  // 再生が始まったときと、その2秒後に、音を消す理由がないのにミュートなら、アプリに知らせる（作り直してもらう）。
  var playing = false;
  var autoMutedSent = false;
  function checkAutoMuted() {
    if (autoMutedSent || suppressed || !player.getMuted()) return;
    autoMutedSent = true;
    if (window.$_channel) $_channel.postMessage("autoMuted");
  }
  player.addEventListener(Twitch.Player.PLAYING, function () {
    if (playing) return;
    playing = true;
    checkAutoMuted();
    setTimeout(checkAutoMuted, 2000);
  });
  // 戻ってきたときは、ミュートを変えずに再生だけし直す（ユーザーが解除した音を消さない）。
  window.resumePlayback = function () { player.play(); };
  // 前で別の動画が音を出す間は消し、終わったら、消す前の状態（ミュートか）に戻す。
  // 前の動画（YouTube）が音を出すと、iOS は後ろの映像を止めることがあるので、戻すときは再生し直す。
  // 固定ビューアは、投稿ビューアの上に見えたまま残るので、音を消している間も、止められたら音なしで流し直す
  // （前の動画が音を出し始めるまで少しかかるので、少し待って何回か確かめる）。
  function keepPlayingMuted() {
    if (suppressed && player.isPaused()) player.play();
  }
  window.suppressAudio = function (on) {
    if (on === suppressed) return;
    suppressed = on;
    if (!ready) return;
    if (on) {
      if (mutedBefore === null) mutedBefore = player.getMuted();
      player.setMuted(true);
      [1000, 3000, 6000].forEach(function (ms) { setTimeout(keepPlayingMuted, ms); });
    } else {
      if (mutedBefore !== null) {
        player.setMuted(mutedBefore);
        mutedBefore = null;
      }
      if (player.isPaused()) player.play();
    }
  };
</script>
</body>
</html>
''';

String _youtubeHtml(
  String videoId, {
  int start = 0,
  required bool audioSuppressed,
}) =>
    '''
<!doctype html>
<html>
<head>
$_style
</head>
<body>
<div id="player"></div>
$_failScript
<script src="https://www.youtube.com/iframe_api" onerror="notifyFailed()"></script>
<script>
  var player;
  // 前で別の動画が音を出しているか。準備ができるまでは、ここに覚えておく。
  var suppressed = $audioSuppressed;
  var mutedBefore = null;
  // 一度でも再生が始まったか。
  var played = false;
  function start() {
    ready = true;
    // 音を消している間は、消したまま始め、前の動画が終わったら音を出す。
    if (suppressed) {
      player.mute();
      mutedBefore = false;
    } else {
      player.unMute();
    }
    hideCaptions();
    // 再生は、アプリが命令する（低電力モードでは、ページの JS からの再生は止められる）。
    if (window.$_channel) $_channel.postMessage("ready");
  }
  // アプリから呼ぶ。準備ができたときの再生。
  window.startPlayback = function () { player.playVideo(); };
  // アプリから呼ぶ。一度も再生が始まっていなければ、再生し直す。始まったあとは何もしない。読み込み中（3）は待つ。
  window.retryPlayback = function () {
    if (played) return;
    if (player.getPlayerState() !== 3) player.playVideo();
  };
  // 字幕は、はじめは出さない。字幕のモジュールは再生が始まってから読み込まれることがあるので、始まったときにも外す。
  // ユーザーがプレイヤーの字幕のボタンで出したものは、そのままにする（始まったときの1回だけ外す）。
  function hideCaptions() {
    if (!player.unloadModule) return;
    player.unloadModule("captions");
    player.unloadModule("cc");
  }
  // 再生が始まった（1）か、再生できないと分かったら、アプリに知らせる（サムネイルを外す）。
  // 再生できないときは、notifyFailed でも知らせる（配信では「もう一度試す」を出す）。
  function notifyStarted() {
    if (window.$_channel) $_channel.postMessage("started");
  }
  function onYouTubeIframeAPIReady() {
    player = new YT.Player("player", {
      videoId: ${_js(videoId)},
      width: "100%",
      height: "100%",
      playerVars: {
        autoplay: 1,
        playsinline: 1,
        rel: 0,
        // 字幕を、ユーザーの設定で勝手に出さない。
        cc_load_policy: 0,
        start: $start,
        mute: ${audioSuppressed ? 1 : 0}
      },
      events: {
        onReady: start,
        onStateChange: function (e) {
          if (e.data === 1) {
            if (!played) hideCaptions();
            played = true;
            notifyStarted();
            if (window.$_channel) $_channel.postMessage("playing");
          }
          // 最後まで再生した（0）。ランダム再生で、次の動画に進む。
          if (e.data === 0 && window.$_channel) $_channel.postMessage("ended");
          // 一時停止した（2）。固定ビューアで、配信に切り替えて戻したとき、止めたままにする。
          if (e.data === 2 && window.$_channel) $_channel.postMessage("paused");
        },
        onError: function () { notifyStarted(); notifyFailed(); }
      }
    });
  }
  // 戻ってきたときは、ミュートを変えずに再生だけし直す（ユーザーが解除した音を消さない）。
  window.resumePlayback = function () {
    if (player && player.playVideo) player.playVideo();
  };
  // いまの再生位置（秒）。固定ビューアと投稿ビューアの間や、固定ビューアを開き直したときに、続きから流すのに使う。
  // 配信中（生配信）は、位置から始めると再生できないので、分からない（-1）とする（いちばん新しい位置から流す）。
  window.currentTime = function () {
    if (!player || !player.getCurrentTime) return -1;
    var data = player.getVideoData ? player.getVideoData() : null;
    if (data && data.isLive) return -1;
    return player.getCurrentTime();
  };
  // 動画の長さ（秒）。準備の前と、生配信は、分からない（-1）とする（早送り・巻き戻しをしない）。
  window.videoDuration = function () {
    if (!ready || !player || !player.getDuration) return -1;
    var data = player.getVideoData ? player.getVideoData() : null;
    if (data && data.isLive) return -1;
    var d = player.getDuration();
    return d > 0 ? d : -1;
  };
  // 再生位置を動かす（固定ビューアのコントローラーの早送り・巻き戻し）。読み込んでいない所へも動かす。
  // play なら、止まっていても再生する（指を離したとき、そこから流す）。
  window.seekVideo = function (seconds, play) {
    if (!ready || !player || !player.seekTo) return;
    player.seekTo(seconds, true);
    if (play && player.getPlayerState() !== 1) player.playVideo();
  };
  // 前で別の動画が音を出す間は消し、終わったら、消す前の状態（ミュートか）に戻す。
  // 前の動画（YouTube）が音を出すと、iOS は後ろの映像を止めることがあるので、戻すときは再生し直す。
  // 配信なら、止まっていた間に遅れたぶん、いちばん新しい位置まで進める。
  window.suppressAudio = function (on) {
    if (on === suppressed) return;
    suppressed = on;
    if (!ready) return;
    if (on) {
      if (mutedBefore === null) mutedBefore = player.isMuted();
      player.mute();
    } else {
      if (mutedBefore !== null) {
        if (!mutedBefore) player.unMute();
        mutedBefore = null;
      }
      if (player.getPlayerState() !== 1) {
        var data = player.getVideoData ? player.getVideoData() : null;
        if (data && data.isLive) player.seekTo(player.getDuration(), true);
        player.playVideo();
      }
    }
  };
</script>
</body>
</html>
''';

String _iframeHtml(String url) {
  final src = const HtmlEscape(HtmlEscapeMode.attribute).convert(url);
  return '''
<!doctype html>
<html>
<head>
$_style
</head>
<body>
<iframe id="player" src="$src" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" allowfullscreen></iframe>
</body>
</html>
''';
}
