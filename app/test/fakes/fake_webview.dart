import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// 埋め込みプレイヤー（WebView）の代わり。読み込んだページを覚え、灰色の箱を出す。
class FakeWebViewPlatform extends WebViewPlatform {
  /// 読み込んだページ（HTML）。
  static final loadedHtml = <String>[];

  /// ページを読み込んだときの土台の URL（`Referer` になる）。
  static final loadedBaseUrls = <String?>[];

  /// ページからアプリへ知らせる窓口。テストから知らせを送るのに使う。
  static final channels = <JavaScriptChannelParams>[];

  /// ページで走らせた JavaScript。
  static final scripts = <String>[];

  /// ページを読み込み終えたときの知らせ。テストから、読み込み終えたことにするのに使う。
  static final pageFinished = <PageEventCallback>[];

  /// 開いた URL。
  static final loadedUrls = <Uri>[];

  /// JavaScript の結果として返す値。null なら、プレイヤーの再生位置（12.5 秒）を返す。
  static Object? scriptResult;

  /// 走らせた JavaScript ごとに結果を返す。null を返したら、[scriptResult] を使う。
  static Object? Function(String javaScript)? scriptHandler;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => _FakeWebViewController(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => _FakeWebViewWidget(params);
}

class _FakeWebViewController extends PlatformWebViewController {
  _FakeWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    FakeWebViewPlatform.loadedHtml.add(html);
    FakeWebViewPlatform.loadedBaseUrls.add(baseUrl);
  }

  @override
  Future<void> runJavaScript(String javaScript) async =>
      FakeWebViewPlatform.scripts.add(javaScript);

  /// [FakeWebViewPlatform.scriptHandler]・[FakeWebViewPlatform.scriptResult] を返す。なければ、プレイヤーの再生位置を聞かれたとして、12.5 秒と答える。
  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async {
    FakeWebViewPlatform.scripts.add(javaScript);
    return FakeWebViewPlatform.scriptHandler?.call(javaScript) ??
        FakeWebViewPlatform.scriptResult ??
        12.5;
  }

  @override
  Future<void> loadRequest(LoadRequestParams params) async =>
      FakeWebViewPlatform.loadedUrls.add(params.uri);

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async =>
      FakeWebViewPlatform.channels.add(params);
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async =>
      FakeWebViewPlatform.pageFinished.add(onPageFinished);

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}
}

class _FakeWebViewWidget extends PlatformWebViewWidget {
  _FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) =>
      const ColoredBox(key: Key('fake-webview'), color: Colors.grey);
}
