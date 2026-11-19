import '../../utils/formatters.dart';

/// チケットの URL から読み取った、イベントの下書き（Edge Function `read-event-url`。機能仕様書 4.5.2）。
class EventDraft {
  const EventDraft({required this.title, required this.performances});

  /// 関数が返した `{ title, performances }` から作る。
  factory EventDraft.fromJson(Map<String, dynamic> json) => EventDraft(
    title: json['title'] as String?,
    performances: [
      for (final p in (json['performances'] as List? ?? const []))
        ?PerformanceDraft.tryParse(p as Map<String, dynamic>),
    ],
  );

  /// タイトル。読み取れなければ null。
  final String? title;

  /// 公演（日付順）。
  final List<PerformanceDraft> performances;
}

/// 読み取った公演の1つ。時刻は日本時間。分からない項目は null。
class PerformanceDraft {
  const PerformanceDraft({
    required this.date,
    this.start,
    this.end,
    this.venue,
    this.url,
  });

  /// `{ date: "YYYY-MM-DD", start: "HH:MM", end, venue, url }` から作る。日付が読めなければ null。
  static PerformanceDraft? tryParse(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date'] as String? ?? '');
    if (date == null) return null;
    return PerformanceDraft(
      date: dateOnly(date),
      start: _time(json['start']),
      end: _time(json['end']),
      venue: json['venue'] as String?,
      url: json['url'] as String?,
    );
  }

  static ({int hour, int minute})? _time(Object? raw) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw as String? ?? '');
    if (m == null) return null;
    return (hour: int.parse(m[1]!), minute: int.parse(m[2]!));
  }

  final DateTime date;
  final ({int hour, int minute})? start;
  final ({int hour, int minute})? end;
  final String? venue;

  /// 公演のページ（1公演の日時と会場が分かるページ）の URL。
  final String? url;
}

/// イベントの候補。検索結果やアーティストのページにあった、イベントのページへのリンク（画面定義書（設定・発信者向け）2.3.11）。
class EventCandidate {
  const EventCandidate({required this.url, required this.text, this.detail});

  /// イベントのページの URL。
  final String url;

  /// リンクの文字（チケットサイトに書いてあるまま）。
  final String text;

  /// リンクのそばにあった、日付と会場（例：「2026/11/4(水) Zepp Osaka Bayside (大阪府)」）。なければ null。
  final String? detail;
}

/// 名前で探せるチケットサイト（画面定義書（設定・発信者向け）2.3.12）。並びは、公演のページを開く順。
enum TicketSite {
  pia('チケットぴあ'),
  lawson('ローチケ'),
  eplus('イープラス'),
  rakuten('楽天チケット');

  const TicketSite(this.label);

  /// サイトの名前（画面にそのまま出す）。
  final String label;
}

/// 1つのサイトの、1公演のチケット（公演の候補の行の中の1サイト分）。
class TicketOption {
  const TicketOption({
    required this.site,
    required this.url,
    required this.eventTitle,
    String? pageUrl,
  }) : pageUrl = pageUrl ?? url;

  final TicketSite site;

  /// 公演のページ（なければイベントのページ）の URL。
  final String url;

  /// 確かめるときに開くページ。ふつうは [url]。楽天チケットは、申し込みのページ（[url]）はログインが要るので、
  /// イベントのページ。
  final String pageUrl;

  /// イベントの名前。
  final String eventTitle;
}

/// 公演の候補。サイトを横断して、同じ公演を1つにまとめたもの（画面定義書（設定・発信者向け）2.3.13）。
class PerformanceGroup {
  const PerformanceGroup({
    required this.date,
    required this.tickets,
    this.start,
    this.venue,
  });

  /// 公演の日。
  final DateTime date;

  /// 一覧で分かった開演の時刻（イープラス）。分からなければ null。
  final ({int hour, int minute})? start;

  /// 会場（全角の英数字は半角にそろえる）。
  final String? venue;

  /// 売っているサイトごとのチケット（[TicketSite] の順）。1つ以上。
  final List<TicketOption> tickets;

  /// 一覧に出すイベントの名前（最初のサイトのもの）。
  String get eventTitle => tickets.first.eventTitle;
}
