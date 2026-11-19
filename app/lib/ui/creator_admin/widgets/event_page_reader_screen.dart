import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../domain/models/event_draft.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/js_result.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/one_line_text.dart';

/// ページから読み取った結果。
sealed class PageReadOutcome {
  const PageReadOutcome();
}

/// 表示しているページから取り出した部分（HTML の断片）。取り出せなければ空。
class PageHtml extends PageReadOutcome {
  const PageHtml(this.html, {this.url});

  final String html;

  /// 取り出したページの URL（ページの中を移ったら、移った先）。分からなければ null。
  final Uri? url;
}

/// 表示しているページにあった、イベントのページへのリンク（候補）。
class PageCandidates extends PageReadOutcome {
  const PageCandidates(this.candidates);

  final List<EventCandidate> candidates;
}

/// どこから開いたか。下のボタンの文言と、候補を拾うかが変わる。
enum PageReaderMode {
  /// 「読み取る」から。ボタンは「このページから読み取る」。候補を拾う。
  read,

  /// イベントの候補（2.3.11）から。ボタンは「このイベントを登録」。
  register,

  /// 公演の「ページから時刻を読む」から。ボタンは「このページから時刻を読む」。
  readTime,
}

/// ページから読み取る（画面定義書（設定・発信者向け）2.3.10）。発信者が、チケットのページをアプリの中で
/// 自分で開き、「このページから読み取る」を押すと、表示しているページから読み取りに要る部分だけを取り出して返す。
/// ページにイベントのページへのリンクがあれば、「このページのイベントから選ぶ」で、候補の一覧を返す（自動ではたどらない）。
class EventPageReaderScreen extends StatefulWidget {
  const EventPageReaderScreen({
    super.key,
    required this.url,
    this.mode = PageReaderMode.read,
  });

  final Uri url;
  final PageReaderMode mode;

  /// ページを開く。読み取ったら、その結果を返す。閉じたら null。
  /// 出ているスナックバーは先に消す（開いたページの下のボタンに重ならないように）。
  static Future<PageReadOutcome?> open(
    BuildContext context,
    Uri url, {
    PageReaderMode mode = PageReaderMode.read,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return Navigator.of(context).push<PageReadOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EventPageReaderScreen(url: url, mode: mode),
      ),
    );
  }

  /// 渡す中身の上限（文字数）。サーバーの上限と合わせる。
  static const maxChars = 1000000;

  /// 拾う候補の上限。
  static const maxCandidates = 50;

  /// 表示しているページから、読み取りに要る部分だけを取り出す JavaScript。OGP のタイトル、構造化データ
  /// （JSON-LD と、microdata の Event）、本文のうち日付や「開演」「開場」「START」「会場」を含む行。ページ全体は取らない
  /// （ログインしていると、会員の名前などが出るため）。
  static const extractScript = r'''
(() => {
  const parts = [];
  document.querySelectorAll('meta[property="og:title"]').forEach((m) => parts.push(m.outerHTML));
  document.querySelectorAll('script[type="application/ld+json"]').forEach((s) => parts.push(s.outerHTML));
  document.querySelectorAll('[itemtype*="schema.org/Event"]').forEach((e) => parts.push(e.outerHTML));
  const text = document.body ? document.body.innerText : '';
  const lines = text.split('\n').map((l) => l.trim())
    .filter((l) => /\d{4}\s*[\/年.]\s*\d{1,2}|開演|開場|ＳＴＡＲＴ|START|ＯＰＥＮ|OPEN|会場[:：]/.test(l)).slice(0, 500);
  const esc = (t) => t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  parts.push('<div>' + lines.map(esc).join('\n') + '</div>');
  return parts.join('\n');
})()
''';

  /// 表示しているページにある、イベントのページへのリンク（URL と、リンクの文字）を拾う JavaScript。
  /// URL の形で見分け、イベントのページの URL にそろえる（チケットぴあは `eventBundleCd`・`eventCd` の2つの形・イープラス・ローチケ・ZAIKO・LivePocket・TIGET。
  /// イープラスの公演のページは、イベントのページに直す）。チケットぴあのおすすめの欄（`afid=`）、ページの上下の帯
  /// （ヘッダー・フッター）、いま開いているページ自身は除く。リンクはたどらない。
  static const candidatesScript = r'''
(() => {
  const rules = [
    [/^https:\/\/(?:t|ticket|w)\.pia\.jp\/pia\/event\/event\.do\?(?:[^#]*&)?(eventBundleCd=\w+|eventCd=\d+)/, (m) => 'https://t.pia.jp/pia/event/event.do?' + m[1]],
    [/^https:\/\/eplus\.jp\/sf\/detail\/(\d{10})(?=[-?\/#]|$)/, (m) => 'https://eplus.jp/sf/detail/' + m[1]],
    [/^https:\/\/l-tike\.com\/([a-z]+)\/mevent\/\?(?:[^#]*&)?mid=(\d+)/, (m) => 'https://l-tike.com/' + m[1] + '/mevent/?mid=' + m[2]],
    [/^https:\/\/(?:[a-z0-9-]+\.)?zaiko\.io\/(?:[a-z]{2}\/)?e\/[^\/?#]+/, (m) => m[0]],
    [/^https:\/\/livepocket\.jp\/e\/[^\/?#]+/, (m) => m[0]],
    [/^https:\/\/tiget\.net\/events\/\d+/, (m) => m[0]],
    [/^https:\/\/ticket\.rakuten\.co\.jp\/(?:music|stage|event|sports)\/[^\/?#]+\/rt\w+/, (m) => m[0] + '/'],
  ];
  const here = location.href.split('#')[0].replace(/^http:/, 'https:');
  const seen = new Set();
  const out = [];
  document.querySelectorAll('a[href]').forEach((a) => {
    // ページの上下の帯（人気のキーワードなど）は除く。結果のカードの中の header（ぴあ）は除かない。
    const band = a.closest('header, footer, nav');
    if (band && !(band.parentElement && band.parentElement.closest('main, article, section, li'))) return;
    const raw = a.href.split('#')[0].replace(/^http:/, 'https:');
    if (/[?&]afid=/.test(raw)) return;
    let url = null;
    for (const [re, to] of rules) {
      const m = raw.match(re);
      if (m) { url = to(m); break; }
    }
    if (!url || url === here || seen.has(url)) return;
    const text = (a.innerText || a.textContent || '').normalize('NFKC').replace(/\s+/g, ' ').trim();
    if (!text) return;
    seen.add(url);
    // リンクのカードにある、公演の日付と会場（ぴあの「2026/11/12(木)・11/13(金) NIIGATA LOTS (新潟県)」）。
    // 会場ごとに日付をまとめる。会場名の中の括弧は含め、締切の日時（「～10/27(火) 23:59」）は拾わない。
    const card = a.closest('section, li, article');
    const days = new Map();
    let year = null;
    if (card) {
      const t = (card.innerText || card.textContent || '').normalize('NFKC').replace(/\s+/g, ' ');
      for (const m of t.matchAll(/(\d{4})\/(\d{1,2}\/\d{1,2})\s*(\([^)]*\))\s*(?!\d)([^\/]{1,80}?\([^()]*[都道府県]\))/g)) {
        const venue = m[4].trim();
        const day = m[2] + m[3];
        if (!days.has(venue)) days.set(venue, []);
        const list = days.get(venue);
        if (list.some((d) => d.endsWith(day))) continue;
        list.push((year === null ? m[1] + '/' : '') + day);
        if (year === null) year = m[1];
      }
    }
    const detail = [...days].map(([venue, list]) => list.join('・') + ' ' + venue).join(' / ');
    out.push({ url: url, text: text.slice(0, 200), detail: detail || null });
  });
  return JSON.stringify(out.slice(0, 50));
})()
''';

  /// 候補の JavaScript の結果（JSON の配列）を、候補にする。読めなければ空。
  static List<EventCandidate> parseCandidates(Object result) {
    try {
      final list = jsonDecode(jsResultToString(result)) as List;
      return [
        for (final e in list.take(maxCandidates))
          if (e is Map &&
              e['url'] is String &&
              e['text'] is String &&
              Uri.tryParse(e['url'] as String)?.scheme == 'https')
            EventCandidate(
              url: e['url'] as String,
              text: e['text'] as String,
              detail: e['detail'] as String?,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  State<EventPageReaderScreen> createState() => _EventPageReaderScreenState();
}

class _EventPageReaderScreenState extends State<EventPageReaderScreen> {
  late final WebViewController _controller;
  late String _host = widget.url.host;
  bool _loading = true;
  List<EventCandidate> _candidates = const [];

  /// 読み込み終えたページの URL（https のものだけ）。
  Uri? _pageUrl;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // https のページだけを開く（電話・メール・アプリへの移動などは開かない）。
          onNavigationRequest: (request) =>
              Uri.tryParse(request.url)?.scheme == 'https'
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _candidates = const [];
              _host = Uri.tryParse(url)?.host ?? _host;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;
            final uri = Uri.tryParse(url);
            if (uri?.scheme == 'https') _pageUrl = uri;
            setState(() => _loading = false);
            if (widget.mode == PageReaderMode.read) _findCandidates();
          },
        ),
      )
      ..loadRequest(widget.url);
  }

  /// 表示しているページにある、イベントのページへのリンクを拾う。
  Future<void> _findCandidates() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        EventPageReaderScreen.candidatesScript,
      );
      if (mounted) {
        setState(
          () => _candidates = EventPageReaderScreen.parseCandidates(result),
        );
      }
    } catch (_) {
      // 拾えなければ、候補のボタンを出さない。
    }
  }

  Future<void> _read() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        EventPageReaderScreen.extractScript,
      );
      var html = jsResultToString(result);
      if (html.length > EventPageReaderScreen.maxChars) {
        html = html.substring(0, EventPageReaderScreen.maxChars);
      }
      if (mounted) Navigator.of(context).pop(PageHtml(html, url: _pageUrl));
    } catch (_) {
      // 取り出せなければ、読み取れなかったとして戻る（登録の画面で知らせる）。
      if (mounted) Navigator.of(context).pop(const PageHtml(''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.commonClose,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: OneLineText(_host, style: const TextStyle(fontSize: 15)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(child: WebViewWidget(controller: _controller)),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.eventPageReaderNote,
                      textAlign: TextAlign.center,
                      style: context.textStyles.hint,
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: switch (widget.mode) {
                        PageReaderMode.read => l10n.eventPageReaderRead,
                        PageReaderMode.register => l10n.eventPageReaderRegister,
                        PageReaderMode.readTime => l10n.eventPageReaderReadTime,
                      },
                      onPressed: _loading ? null : _read,
                    ),
                    if (_candidates.isNotEmpty && !_loading) ...[
                      const SizedBox(height: 8),
                      TonalButton(
                        label: l10n.eventPageReaderCandidates(
                          _candidates.length,
                        ),
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(PageCandidates(_candidates)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
