import 'event.dart';

/// リンクの URL の鍵。サーバーの `public.event_url_key`（supabase/migrations/20261102700000_event_performance_url.sql）
/// と同じ形にする。同じチケットのページを指すリンクは、同じ鍵になる。サーバーの関数を変えたら、ここも合わせる。
String eventUrlKey(String url) {
  final noScheme = url.replaceFirst(RegExp('^[a-zA-Z]+://'), '');
  final host = noScheme
      .split('/')
      .first
      .toLowerCase()
      .replaceFirst(RegExp(r'^www\.'), '');
  final path = url
      .replaceFirst(RegExp('^[a-zA-Z]+://[^/]*'), '')
      .split('#')
      .first
      .split('?')
      .first
      .replaceFirst(RegExp(r'/+$'), '');
  final parts = url.split('#').first.split('?');
  final query = parts.length > 1 ? parts[1] : '';
  String? find(String pattern) => RegExp(
    '(?:^|&)$pattern',
    caseSensitive: false,
  ).firstMatch(query)?.group(1);
  const pia = {'t.pia.jp', 'ticket.pia.jp', 'w.pia.jp'};
  if (pia.contains(host)) {
    final event = find(r'eventCd=(\d+)');
    if (event != null) {
      final rls = find(r'rlsCd=(\d+)');
      return 'pia:event:$event${rls == null ? '' : ':$rls'}';
    }
    final bundle = find(r'eventBundleCd=(\w+)');
    if (bundle != null) return 'pia:bundle:${bundle.toLowerCase()}';
    final lot = find(r'lotRlsCd=(\d+)');
    if (lot != null) return 'pia:lot:$lot';
  }
  final eplus = RegExp(r'^/sf/detail/([0-9A-Za-z-]+)').firstMatch(path);
  if (host == 'eplus.jp' && eplus != null) {
    return 'eplus:${eplus.group(1)!.toLowerCase()}';
  }
  final zaiko = RegExp('/e/([^/]+)').firstMatch(path);
  if (RegExp(r'(^|\.)zaiko\.io$').hasMatch(host) && zaiko != null) {
    return 'zaiko:${zaiko.group(1)!.toLowerCase()}';
  }
  final cleaned = query
      .replaceAll(
        RegExp(
          '(^|&)(utm_[^=&]*|afid|fbclid|gclid)=[^&]*',
          caseSensitive: false,
        ),
        '',
      )
      .replaceFirst(RegExp('^&+'), '');
  return '$host$path${cleaned.isEmpty ? '' : '?$cleaned'}';
}

/// 同じチケットのページを指すリンク（[eventUrlKey] が同じもの）を1本にする。順は、はじめに出たもの。
/// どれかが広告（PR）なら、残す1本も広告にする。
List<EventLink> uniqueEventLinks(Iterable<EventLink> links) {
  final byKey = <String, EventLink>{};
  for (final l in links) {
    final key = eventUrlKey(l.url);
    final kept = byKey[key];
    byKey[key] = kept == null
        ? l
        : EventLink(
            url: kept.url,
            isPromotion: kept.isPromotion || l.isPromotion,
          );
  }
  return byKey.values.toList();
}
