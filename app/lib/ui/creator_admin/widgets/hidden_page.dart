import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 画面に出さずにページを1つ開き、読み込み終えたら JavaScript を1回走らせる（画面定義書（設定・発信者向け）2.3.12）。
/// 発信者が「探す」・アーティストを押したときだけ使う。リンクはたどらない（`https://` 以外と、ほかのページへの移動は止める）。
class HiddenPage {
  HiddenPage() : controller = WebViewController() {
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  final WebViewController controller;

  /// 読み込みを待つ上限。
  static const timeout = Duration(seconds: 20);

  /// 後から描くページを、読み直すまで待つ間と回数（[ready] が真になるまで）。
  static const retryDelay = Duration(milliseconds: 700);
  static const retries = 6;

  /// [url] を開き、読み込み終えたら [script] の結果を返す。開けなければ例外。
  /// [ready] を渡すと、それが真になるまで、少し待って読み直す（後から描くページのため）。
  Future<Object> run(
    Uri url,
    String script, {
    bool Function(Object result)? ready,
  }) async => (await runAll(url, [
    script,
  ], ready: ready == null ? null : (r) => ready(r.single))).single;

  /// [url] を開き、読み込み終えたら [scripts] を順に走らせ、それぞれの結果を返す。開けなければ例外。
  /// メンテナンス中のページに転送されたら [PageUnderMaintenance]。
  /// [ready] を渡すと、それが真になるまで、少し待って読み直す（後から描くページのため）。
  Future<List<Object>> runAll(
    Uri url,
    List<String> scripts, {
    bool Function(List<Object> results)? ready,
  }) async {
    final finished = Completer<void>();
    await controller.setNavigationDelegate(
      NavigationDelegate(
        // 開いたページの中の移動（転送）だけ許す。https 以外は開かない。
        onNavigationRequest: (request) {
          final to = Uri.tryParse(request.url);
          // メンテナンスのお知らせのページ（チケットぴあの深夜の `sorry.pia.jp` など）に転送されたら、知らせる。
          if (to != null &&
              (to.host.startsWith('sorry.') ||
                  to.path.contains('maintenance'))) {
            if (!finished.isCompleted) {
              finished.completeError(const PageUnderMaintenance());
            }
            return NavigationDecision.prevent;
          }
          return to?.scheme == 'https'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
        onPageFinished: (_) {
          if (!finished.isCompleted) finished.complete();
        },
        onWebResourceError: (error) {
          // ページそのものが開けなかったときだけ、失敗にする（画像などの失敗は無視する）。
          if (error.isForMainFrame ?? false) {
            if (!finished.isCompleted) finished.completeError(error);
          }
        },
      ),
    );
    await controller.loadRequest(url);
    await finished.future.timeout(timeout);
    for (var i = 0; ; i++) {
      final results = [
        for (final script in scripts)
          await controller.runJavaScriptReturningResult(script),
      ];
      if (ready == null || ready(results) || i >= retries) return results;
      await Future<void>.delayed(retryDelay);
    }
  }
}

/// 開いたページが、メンテナンスのお知らせのページに転送された。
class PageUnderMaintenance implements Exception {
  const PageUnderMaintenance();
}

/// [HiddenPage] のページを置く場所。スマホと同じ大きさで、画面の外に置く（ページは置いておかないと動かない環境があり、
/// 小さすぎると、画面の幅に合わせて欄を隠すサイト（イープラスなど）があるため）。`Stack` の子に置く。
class HiddenPageView extends StatelessWidget {
  const HiddenPageView({super.key, required this.page});

  final HiddenPage page;

  @override
  Widget build(BuildContext context) => Positioned(
    left: -10000,
    top: 0,
    width: 390,
    height: 844,
    child: ExcludeSemantics(
      child: IgnorePointer(child: WebViewWidget(controller: page.controller)),
    ),
  );
}
