import 'dart:convert';

import '../../utils/js_result.dart';
import '../../utils/search_text.dart';
import 'event_draft.dart';
import 'schedule_item.dart';

/// チケットサイトでヒットしたアーティスト（画面定義書（設定・発信者向け）2.3.12）。
class ArtistHit {
  const ArtistHit({required this.site, required this.name, required this.url});

  final TicketSite site;
  final String name;

  /// アーティストのページ。
  final String url;
}

/// 1つのページから拾った、1公演（まとめる前）。
class PerformanceEntry {
  const PerformanceEntry({
    required this.site,
    required this.date,
    required this.url,
    required this.perfLevel,
    this.start,
    this.venue,
    this.title,
    this.pageUrl,
  });

  final TicketSite site;
  final DateTime date;
  final ({int hour, int minute})? start;
  final String? venue;

  /// 公演のページ（なければイベントのページ）の URL。
  final String url;

  /// [url] が1公演のページか（イベントのページでないか）。
  final bool perfLevel;

  /// イベントの名前。分からなければ null。
  final String? title;

  /// 拾ったページ（イベントのページ）の URL。
  final String? pageUrl;
}

/// チケットサイトの検索と、公演の集め方（tech-risks.md 2.16。2026-10-27 に各サイトのページの形を確かめた）。
/// どのページも、発信者が「探す」「公演を見る」を押したときだけ、画面に出さずに1ページずつ開く。リンクはたどらない。
abstract final class TicketSearch {
  /// [name] の検索結果のページ。
  static Uri searchUrl(TicketSite site, String name) {
    final q = Uri.encodeQueryComponent(name.trim());
    return Uri.parse(switch (site) {
      TicketSite.pia => 'https://t.pia.jp/pia/search_all.do?kw=$q',
      TicketSite.eplus => 'https://eplus.jp/sf/search?keyword=$q',
      TicketSite.lawson => 'https://l-tike.com/search/?keyword=$q',
      TicketSite.rakuten => 'https://ticket.rakuten.co.jp/?s=&q=$q',
    });
  }

  /// 検索結果のページの、アーティストのページへのリンクを拾う JavaScript。
  static String artistsScript(TicketSite site) {
    final rule = switch (site) {
      TicketSite.pia =>
        r"[/^https?:\/\/(?:t|ticket|w)\.pia\.jp\/pia\/artist\/artists\.do\?(?:[^#]*&)?artistsCd=(\w+)/, (m) => 'https://t.pia.jp/pia/artist/artists.do?artistsCd=' + m[1]]",
      TicketSite.eplus =>
        r"[/^https?:\/\/eplus\.jp\/sf\/word\/(\d+)(?:[?#\/]|$)/, (m) => 'https://eplus.jp/sf/word/' + m[1]]",
      TicketSite.lawson =>
        r"[/^https?:\/\/l-tike\.com\/artist\/(\d+)/, (m) => 'https://l-tike.com/artist/' + m[1] + '/']",
      // 楽天チケットは、名前の検索の結果にアーティストが出ない（イベントが直接並ぶ）。[rakutenArtist] を使う。
      TicketSite.rakuten => r"[/(?!)/, (m) => '']",
    };
    return '''
(() => {
  const [re, to] = $rule;
  const seen = new Set();
  const out = [];
  document.querySelectorAll('a[href]').forEach((a) => {
    const band = a.closest('header, footer, nav');
    if (band && !(band.parentElement && band.parentElement.closest('main, article, section, li'))) return;
    const m = a.href.match(re);
    if (!m) return;
    const url = to(m);
    const name = (a.innerText || a.textContent || '').normalize('NFKC').replace(/\\s+/g, ' ').trim();
    if (!name || seen.has(url)) return;
    seen.add(url);
    out.push({ name: name.slice(0, 100), url: url });
  });
  return JSON.stringify(out.slice(0, 30));
})()
''';
  }

  /// イベントのページ（とイープラスのアーティストのページ）から、公演を拾う JavaScript。
  /// チケットぴあは受付のカード（microdata）、ローチケ・イープラスは構造化データ（JSON-LD）、
  /// イープラスは公演ごとの見出し（日付・開演・会場）と、アーティストのページの公演ごとのリンクも読む。
  static const performancesScript = r'''
(() => {
  const out = [];
  const norm = (t) => (t || '').normalize('NFKC').replace(/\s+/g, ' ').trim();
  const pad = (n) => String(n).padStart(2, '0');
  let title = null;
  document.querySelectorAll('[itemtype*="schema.org/Event"]').forEach((e) => {
    const d = e.querySelector('[itemprop="startDate"]');
    const date = d && (d.getAttribute('datetime') || d.getAttribute('content'));
    if (!date) return;
    const link = e.querySelector('[itemprop="url"]');
    const place = e.querySelector('[itemtype*="schema.org/Place"] [itemprop="name"]');
    out.push({ date: date.slice(0, 10), time: null, venue: place ? norm(place.innerText || place.textContent) : '', url: link ? link.href : null });
  });
  const flat = (x) => Array.isArray(x) ? x.flatMap(flat)
    : (x && typeof x === 'object' ? [x, ...(x['@graph'] ? flat(x['@graph']) : [])] : []);
  document.querySelectorAll('script[type="application/ld+json"]').forEach((s) => {
    let data;
    try { data = JSON.parse(s.textContent); } catch (_) { return; }
    flat(data).forEach((n) => {
      const types = [].concat(n['@type'] || []);
      if (!types.some((t) => /Event$/.test(String(t)))) return;
      const m = String(n.startDate || '').match(/^(\d{4}-\d{2}-\d{2})(?:[T ](\d{2}:\d{2}))?/);
      if (!m) return;
      if (!title && n.name) title = norm(String(n.name));
      const loc = [].concat(n.location || [])[0];
      const offer = [].concat(n.offers || [])[0];
      out.push({
        date: m[1],
        time: m[2] && m[2] !== '00:00' ? m[2] : null,
        venue: norm(loc && loc.name),
        url: (offer && offer.url) || n.url || null,
      });
    });
  });
  if (location.hostname === 'ticket.rakuten.co.jp') {
    // 公演ごとの区画（「2026年 12月 12日 (土)公演時間 : 開場 10:30 / 開演 11:00エリア : 東京都会場 : …」）と、
    // その区画の申し込みのリンク。
    const blocks = [...document.querySelectorAll('div, li')].filter((e) => {
      const t = e.textContent || '';
      return /公演時間/.test(t) && /会場/.test(t) && /\d{4}\s*年/.test(t) && t.length < 400;
    });
    blocks.filter((b) => !blocks.some((o) => o !== b && b.contains(o))).forEach((b) => {
      const t = norm(b.innerText || b.textContent);
      const d = t.match(/(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*日/);
      if (!d) return;
      const time = t.match(/開演\s*(\d{1,2}):(\d{2})/);
      const v = t.match(/会場\s*[:：]\s*(.+?)\s*$/);
      const box = b.parentElement || b;
      const link = box.querySelector('a[href*="/cart/performances/"]') || b.querySelector('a[href*="/cart/performances/"]');
      out.push({ date: d[1] + '-' + pad(d[2]) + '-' + pad(d[3]), time: time ? pad(time[1]) + ':' + time[2] : null, venue: v ? v[1] : '', url: link ? link.href.split('?')[0] : null });
    });
  }
  if (/(^|\.)eplus\.jp$/.test(location.hostname)) {
    document.querySelectorAll('h3').forEach((h) => {
      const t = norm(h.innerText || h.textContent);
      const d = t.match(/(\d{4})\/(\d{1,2})\/(\d{1,2})/);
      const time = t.match(/開演[:：]\s*(\d{1,2}):(\d{2})/);
      if (!d || !time) return;
      // 会場は「(開場 …)」のあと。会場名の中の括弧は残し、最後の都道府県の括弧だけ除く。
      const venue = t.replace(/^.*開場[^)]*\)\s*/, '').replace(/\s*\([^()]*[都道府県]\)\s*$/, '');
      out.push({ date: d[1] + '-' + pad(d[2]) + '-' + pad(d[3]), time: pad(time[1]) + ':' + time[2], venue: venue === t ? '' : venue, url: null });
    });
    document.querySelectorAll('a[href*="/sf/detail/"]').forEach((a) => {
      if (!/\/sf\/detail\/\d{10}-P/.test(a.href)) return;
      const t = norm(a.innerText || a.textContent);
      const dates = [...t.matchAll(/(\d{4})\/\s*(\d{1,2})\/(\d{1,2})/g)];
      if (dates.length !== 1) return;
      const d = dates[0];
      const time = t.match(/開演[:：]\s*(\d{1,2}):(\d{2})/);
      out.push({ date: d[1] + '-' + pad(d[2]) + '-' + pad(d[3]), time: time ? pad(time[1]) + ':' + time[2] : null, venue: '', url: a.href.split('?')[0] });
    });
  }
  if (!title) {
    const og = document.querySelector('meta[property="og:title"]');
    if (og) title = norm(og.content).split(/\s*[|｜]\s*/)[0].replace(/のチケット情報.*$/, '');
  }
  return JSON.stringify({ title: title, performances: out.slice(0, 300) });
})()
''';

  /// 楽天チケットの検索結果を、1人のアーティストの代わりにする（名前の検索の結果に、イベントが直接並ぶため）。
  /// [candidates] は、検索結果のページから拾ったイベントのページへのリンク。なければ空。
  static List<ArtistHit> rakutenArtist(
    String name,
    List<EventCandidate> candidates,
    String Function(String name, int count) label,
  ) => candidates.isEmpty
      ? const []
      : [
          ArtistHit(
            site: TicketSite.rakuten,
            name: label(name.trim(), candidates.length),
            url: searchUrl(TicketSite.rakuten, name).toString(),
          ),
        ];

  /// [artistsScript] の結果を、アーティストにする。読めなければ空。
  static List<ArtistHit> parseArtists(TicketSite site, Object result) {
    try {
      final list = jsonDecode(jsResultToString(result)) as List;
      return [
        for (final e in list)
          if (e is Map && e['name'] is String && e['url'] is String)
            ArtistHit(
              site: site,
              name: e['name'] as String,
              url: e['url'] as String,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// [performancesScript] の結果を、公演にする。公演のページの URL がなければ、[pageUrl]（イベントのページ）にする。
  /// イベントの名前は、チケットぴあはリンクの文字（[linkTitle]）、ほかはページの名前を使う。
  /// アーティストのページから拾うとき（[titled] が偽）は、名前を付けない（ページの名前は、販売の名前のため）。
  static List<PerformanceEntry> parsePerformances(
    TicketSite site,
    Object result, {
    required String pageUrl,
    String? linkTitle,
    bool titled = true,
  }) {
    final Map data;
    try {
      data = jsonDecode(jsResultToString(result)) as Map;
    } catch (_) {
      return const [];
    }
    final pageTitle = data['title'] as String?;
    // シャトルバス・駐車券・グッズなどの券は、公演ではないので拾わない（ローチケの「【シャトルバス】…」など）。
    if (_notPerformance.hasMatch('${pageTitle ?? ''} ${linkTitle ?? ''}')) {
      return const [];
    }
    final title = !titled
        ? null
        : site == TicketSite.pia
        ? (linkTitle ?? pageTitle)
        : (pageTitle ?? linkTitle);
    final out = <PerformanceEntry>[];
    for (final e in (data['performances'] as List? ?? const [])) {
      if (e is! Map || e['date'] is! String) continue;
      final m = RegExp(
        r'^(\d{4})-(\d{2})-(\d{2})$',
      ).firstMatch(e['date'] as String);
      if (m == null) continue;
      final t = RegExp(
        r'^(\d{2}):(\d{2})$',
      ).firstMatch(e['time'] as String? ?? '');
      final raw = (e['url'] as String?)?.replaceFirst(
        RegExp('^http:'),
        'https:',
      );
      final url = raw != null && raw.startsWith('https://') ? raw : pageUrl;
      final venue = (e['venue'] as String?)?.trim();
      out.add(
        PerformanceEntry(
          site: site,
          date: DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!)),
          start: t == null
              ? null
              : (hour: int.parse(t[1]!), minute: int.parse(t[2]!)),
          venue: venue == null || venue.isEmpty ? null : venue,
          url: url,
          perfLevel: url != pageUrl && _isPerfLevel(url),
          title: title,
          pageUrl: pageUrl,
        ),
      );
    }
    return out;
  }

  /// 公演ではない券（シャトルバス・駐車券・グッズなど）の名前。
  static final _notPerformance = RegExp(
    r'シャトルバス|駐車券|駐車場|バス券|バスツアー|グッズ|物販|入店整理券',
  );

  /// アーティストの名前を、比べるための形にする。括弧の補足（「(アイドルVtuber)」）と記号（♡・☆など）を除く。
  static String nameKey(String name) => venueKey(
    name.replaceAll(RegExp(r'\s*[（(][^()（）]*[）)]\s*$'), ''),
  ).replaceAll(RegExp(r'[♡♥❤☆★♪!！?？~〜\-_/／]'), '');

  /// [artists]（1つのサイト）のうち、[name] のアーティストらしいもの。同じ名前（大文字・小文字と空白の違いだけ）が
  /// あればそれ、なければ括弧の補足と記号を除いて1人だけ合うもの。同じ名前で記号を除かないのは、「Ado」と「A.D.O」の
  /// ように、記号だけが違う別のアーティストがいるため。
  static List<ArtistHit> likelyArtists(List<ArtistHit> artists, String name) {
    String same(String t) => t.toLowerCase().replaceAll(RegExp(r'\s'), '');
    final exact = [
      for (final a in artists)
        if (same(a.name) == same(name)) a,
    ];
    if (exact.isNotEmpty) return exact;
    final loose = [
      for (final a in artists)
        if (nameKey(a.name) == nameKey(name)) a,
    ];
    return loose.length == 1 ? loose : const [];
  }

  /// [url] が [site] のページか。アーティストのページには、ほかのサイト（ZAIKO・LivePocket など）のイベントへの
  /// リンクもあるので、そのサイトの解析に渡す前に、ホストで絞る。
  static bool onSite(TicketSite site, String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    bool under(String domain) => host == domain || host.endsWith('.$domain');
    return switch (site) {
      TicketSite.pia => under('pia.jp'),
      TicketSite.lawson => under('l-tike.com'),
      TicketSite.eplus => under('eplus.jp'),
      TicketSite.rakuten => host == 'ticket.rakuten.co.jp',
    };
  }

  /// 1公演のページか（チケットぴあの受付、イープラスの `-P…`、ローチケの申し込み）。
  static bool _isPerfLevel(String url) =>
      url.contains('ticketInformation.do') ||
      RegExp(r'/sf/detail/\d{10}-P').hasMatch(url) ||
      url.contains('l-tike.com/order/') ||
      url.contains('ticket.rakuten.co.jp/cart/performances/');

  /// 公演のページとしての良さ。チケットぴあの抽選（終わると中身が出ない）は後回しにする。
  static int _rank(PerformanceEntry e) =>
      !e.perfLevel ? 0 : (RegExp('[?&]lotRlsCd=').hasMatch(e.url) ? 1 : 2);

  /// 会場名を、比べるための形にする（全角・半角、空白、都道府県の括弧をそろえる）。登録済みの会場名は手入力の
  /// ことがあるので、検索と同じ正規化（NFKC。全角の英数字「Ｚｅｐｐ」、結合文字の濁点など）でそろえてから比べる。
  static String venueKey(String? venue) => normalizeForSearch(venue ?? '')
      .replaceAll(RegExp(r'[（(][^()（）]*[都道府県][）)]'), '')
      .replaceAll(RegExp(r'[\s・･、,.()（）「」\[\]［］]'), '');

  static bool _sameVenue(String a, String b) =>
      a.isEmpty || b.isEmpty || a == b || a.contains(b) || b.contains(a);

  /// 会場名の似かた（2文字ずつの並びの重なり。0〜1）。書き方の違い（「宮城・セキスイハイム」と「宮城セキスイハイム」、
  /// 括弧の有無など）を、同じ会場とみなすのに使う。
  static double venueSimilarity(String a, String b) {
    Set<String> grams(String t) => {
      for (var i = 0; i + 1 < t.length; i++) t.substring(i, i + 2),
    };
    final x = grams(a), y = grams(b);
    if (x.isEmpty || y.isEmpty) return 0;
    return x.intersection(y).length / x.union(y).length;
  }

  /// 同じ会場とみなす、会場名の似かたの下限。
  static const _similarVenue = 0.4;

  static bool _venueMatches(String a, String b) =>
      _sameVenue(a, b) || venueSimilarity(a, b) >= _similarVenue;

  static bool _timeMatches(
    ({int hour, int minute})? a,
    ({int hour, int minute})? b,
  ) => a == null || b == null || a == b;

  /// [group] と同じ公演が、[registered]（発信者のイベントの公演）にあるか。同じ日で、会場が同じとみなせて、
  /// 開演の時刻が食い違わない（どちらかが分からない・同じ）ものがあれば、登録済みとみなす。チケットリンクの URL が
  /// 変わっても（チケットぴあの受付が終わって別の受付になったなど）、二重に登録しないため。
  static bool alreadyRegistered(
    PerformanceGroup group,
    List<ScheduleItem> registered,
  ) => registered.any((s) {
    if (s.eventId == null) return false;
    final local = s.startsAt.toLocal();
    if (local.year != group.date.year ||
        local.month != group.date.month ||
        local.day != group.date.day) {
      return false;
    }
    if (!_venueMatches(venueKey(s.venue), venueKey(group.venue))) return false;
    final start = s.allDay ? null : (hour: local.hour, minute: local.minute);
    return _timeMatches(start, group.start);
  });

  /// 公演を、サイトを横断して1公演1つにまとめ、日付と開演の順に並べる。[today] より前の公演は除く。
  /// 同じ日で、会場が同じ（会場名が同じ・一方が他方を含む・よく似ている・どちらかが分からない）で、開演の時刻が
  /// 食い違わない（どちらかが分からない・同じ）ものを、同じ公演とみなす。開演の時刻が違えば、昼夜の公演として分ける。
  /// 開演の時刻が分からない公演（チケットぴあ・ローチケ）は、同じ会場の、いちばん早い公演にまとめる。会場の分かる
  /// 公演が、会場の分からないもの（イープラスのリンクだけのもの）を介して、別の会場の公演にまとまらないよう、
  /// まとまりの会場は、分かっているものだけで比べる。
  static List<PerformanceGroup> group(
    List<PerformanceEntry> entries,
    DateTime today,
  ) {
    final byDate = <DateTime, List<PerformanceEntry>>{};
    for (final e in entries) {
      if (e.date.isBefore(today)) continue;
      byDate.putIfAbsent(e.date, () => []).add(e);
    }
    int minutes(({int hour, int minute})? t) =>
        t == null ? 24 * 60 : t.hour * 60 + t.minute;
    final groups = <PerformanceGroup>[];
    for (final date in byDate.keys.toList()..sort()) {
      // 時刻の分かるもの、会場だけ分かるもの、どちらも分からないもの（イープラスのリンクだけのもの）の順にまとめる。
      int order(PerformanceEntry e) =>
          e.start != null ? 0 : (e.venue != null ? 1 : 2);
      final list = [...byDate[date]!]
        ..sort((a, b) {
          final o = order(a) - order(b);
          return o != 0 ? o : minutes(a.start) - minutes(b.start);
        });
      final clusters = <_Cluster>[];
      for (final e in list) {
        final key = venueKey(e.venue);
        final hits = clusters.where((c) {
          if (!_timeMatches(c.start, e.start)) return false;
          final known = c.venueKeys;
          return key.isEmpty ||
              known.isEmpty ||
              known.any((v) => _venueMatches(v, key));
        }).toList();
        // 開演が同じもの、会場が分かって合うもの、の順に選ぶ。
        final hit =
            hits
                .where((c) => c.start != null && c.start == e.start)
                .firstOrNull ??
            hits
                .where((c) => key.isNotEmpty && c.venueKeys.isNotEmpty)
                .firstOrNull ??
            hits.firstOrNull;
        if (hit == null) {
          clusters.add(_Cluster(e));
        } else {
          hit.add(e);
        }
      }
      clusters.sort((a, b) => minutes(a.start) - minutes(b.start));
      for (final c in clusters) {
        final tickets = <TicketOption>[];
        for (final site in TicketSite.values) {
          final ofSite = c.entries.where((e) => e.site == site).toList()
            ..sort((a, b) => _rank(b) - _rank(a));
          if (ofSite.isEmpty) continue;
          final title = ofSite
              .map((e) => e.title)
              .firstWhere((t) => t != null && t.isNotEmpty, orElse: () => null);
          final best = ofSite.first;
          tickets.add(
            TicketOption(
              site: site,
              url: best.url,
              eventTitle: title ?? '',
              // 楽天チケットの申し込みのページはログインが要るので、確かめるときはイベントのページを開く。
              pageUrl: site == TicketSite.rakuten ? best.pageUrl : null,
            ),
          );
        }
        final venue = c.entries
            .map((e) => e.venue)
            .firstWhere((v) => v != null, orElse: () => null);
        groups.add(
          PerformanceGroup(
            date: date,
            start: c.start,
            venue: venue,
            tickets: tickets,
          ),
        );
      }
    }
    return groups;
  }
}

/// 同じ公演とみなした、公演のまとまり。
class _Cluster {
  _Cluster(PerformanceEntry first) : entries = [first], start = first.start;

  final List<PerformanceEntry> entries;

  /// 開演の時刻（まとめたどれかで分かったもの）。
  ({int hour, int minute})? start;

  /// 分かっている会場名（比べるための形）。
  Iterable<String> get venueKeys => [
    for (final e in entries)
      if (TicketSearch.venueKey(e.venue) case final k when k.isNotEmpty) k,
  ];

  void add(PerformanceEntry e) {
    entries.add(e);
    start ??= e.start;
  }
}
