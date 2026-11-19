import 'schedule_item.dart';

/// イベント（`events` の1行と、リンク・公演。データ設計書 3.1.17・3.1.18）。発信者1人のもの。
class Event {
  const Event({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.links,
    required this.performances,
  });

  final String id;
  final String creatorId;
  final String title;

  /// チケットサイトなどのリンク（並び順）。
  final List<EventLink> links;

  /// 公演（予定の行。日時の順）。
  final List<ScheduleItem> performances;
}

/// イベントのリンク（`event_links` の1行）。広告（PR）かは、リンクごとに持つ。
class EventLink {
  const EventLink({required this.url, this.isPromotion = false});

  factory EventLink.fromRow(Map<String, dynamic> row) => EventLink(
    url: row['url'] as String,
    isPromotion: (row['is_promotion'] as bool?) ?? false,
  );

  final String url;
  final bool isPromotion;

  /// ツイキャスのページか。ツイキャスの名前は英語で表記が変わるので、View で `snsServiceName` から引く（i18n設計書 6.1）。
  bool get isTwitCasting {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'twitcasting.tv' || host.endsWith('.twitcasting.tv');
  }

  /// ボタンに出すサイトの名前（「チケットぴあ」など）。知らないサイトは、ドメイン（www. を除く）。
  /// ツイキャスは [isTwitCasting] を見て、View で名前を引く。
  String get siteName {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    for (final (suffix, name) in _sites) {
      if (host == suffix || host.endsWith('.$suffix')) return name;
    }
    return host.startsWith('www.') ? host.substring(4) : host;
  }

  static const _sites = [
    ('pia.jp', 'チケットぴあ'),
    ('eplus.jp', 'イープラス'),
    ('l-tike.com', 'ローチケ'),
    ('zaiko.io', 'ZAIKO'),
    ('livepocket.jp', 'LivePocket'),
    ('tiget.net', 'TIGET'),
    ('peatix.com', 'Peatix'),
    ('teket.jp', 'teket'),
    ('ticketdive.com', 'TicketDive'),
    ('eventbrite.com', 'Eventbrite'),
    ('eventbrite.jp', 'Eventbrite'),
    ('tixplus.jp', 'チケプラ'),
    ('ticket.rakuten.co.jp', '楽天チケット'),
    ('hulu.jp', 'Hulu'),
  ];
}

/// イベントを保存できなかった理由。
enum EventSaveError {
  /// 同じチケットのページを指すリンクが、この発信者のほかのイベントにある。
  duplicateLink,

  /// 保存（削除）に失敗した。
  failed,
}

/// イベントを保存できなかったときの例外。
class EventSaveException implements Exception {
  const EventSaveException(this.error);

  final EventSaveError error;
}
