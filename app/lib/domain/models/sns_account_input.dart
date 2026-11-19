import 'sns_service.dart';

/// 追いたい（機能仕様書（届ける・広める）4.5.1）で申告する SNS のアカウント。
/// [account] は、サーバーの `want_account` に渡す、そろえた形。
/// YouTube はチャンネル ID（`UC` で始まる）か、`@` を付けて小文字にしたハンドル。ほかの SNS は小文字にした ID。
/// 形は、サーバーの `private.want_account_valid`（supabase/migrations/20261115510000_wants.sql）と合わせる。
class SnsAccountInput {
  const SnsAccountInput(this.service, this.account);

  final SnsService service;
  final String account;

  @override
  bool operator ==(Object other) =>
      other is SnsAccountInput &&
      other.service == service &&
      other.account == account;

  @override
  int get hashCode => Object.hash(service, account);

  @override
  String toString() => 'SnsAccountInput(${service.name}, $account)';

  /// 入れた SNS の URL か ID を、そろえた形にする。読めなければ null。
  /// URL なら、SNS はホストから決める（[service] を渡していて違えば null）。ID だけなら、[service] が要る。
  /// SNS の API でアカウントがあるかは確かめない（形だけを見る）。
  static SnsAccountInput? parse(String input, {SnsService? service}) {
    final text = input.trim().replaceAll('＠', '@');
    if (text.isEmpty || RegExp(r'\s').hasMatch(text)) return null;
    final fromUrl = _hostService(text);
    if (fromUrl != null) {
      final (urlService, segments) = fromUrl;
      if (service != null && service != urlService) return null;
      final account = _accountFromPath(urlService, segments);
      return account == null ? null : _normalize(urlService, account);
    }
    if (text.contains('/') || service == null) return null;
    return _normalize(service, text);
  }

  /// URL なら、SNS とパスの区切りを返す。追星が扱う SNS の URL でなければ null。
  static (SnsService, List<String>)? _hostService(String text) {
    final withScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(text)
        ? text
        : 'https://$text';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasAuthority) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final host = uri.host
        .toLowerCase()
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceFirst(RegExp(r'^(www|m|mobile)\.'), '');
    final service = switch (host) {
      'youtube.com' => SnsService.youtube,
      'x.com' || 'twitter.com' => SnsService.x,
      'instagram.com' => SnsService.instagram,
      'twitch.tv' => SnsService.twitch,
      'twitcasting.tv' => SnsService.twitcasting,
      _ => null,
    };
    if (service == null) return null;
    final List<String> segments;
    try {
      segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    } on FormatException {
      return null; // 壊れた % の書き方
    }
    return (service, segments);
  }

  /// URL のパスから、アカウントの部分を取り出す。アカウントのページでなければ null。
  static String? _accountFromPath(SnsService service, List<String> segments) {
    if (segments.isEmpty) return null;
    final first = segments.first;
    switch (service) {
      case SnsService.youtube:
        // youtube.com/@ハンドル と youtube.com/channel/UC… だけ。動画・/c/・/user/ は、チャンネルが決まらないので読まない。
        if (first.startsWith('@')) return first;
        if (first == 'channel' && segments.length > 1) {
          final id = segments[1];
          return _youtubeChannel.hasMatch(id) ? id : null;
        }
        return null;
      case SnsService.instagram:
        if (first == 'stories' && segments.length > 1) {
          return _instagramReserved.contains(segments[1].toLowerCase())
              ? null
              : segments[1];
        }
        return _instagramReserved.contains(first.toLowerCase()) ? null : first;
      case SnsService.x:
        return _xReserved.contains(first.toLowerCase()) ? null : first;
      case SnsService.twitch:
        return _twitchReserved.contains(first.toLowerCase()) ? null : first;
      case SnsService.twitcasting:
        return first.contains('.') ? null : first; // indexpage.php などのページ
    }
  }

  /// ID を、SNS ごとの形にそろえる。形が違えば null。
  static SnsAccountInput? _normalize(SnsService service, String raw) {
    if (service == SnsService.youtube) {
      if (_youtubeChannel.hasMatch(raw)) return SnsAccountInput(service, raw);
      final handle = (raw.startsWith('@') ? raw.substring(1) : raw)
          .toLowerCase();
      return _youtubeHandle.hasMatch(handle)
          ? SnsAccountInput(service, '@$handle')
          : null;
    }
    final id = (raw.startsWith('@') ? raw.substring(1) : raw).toLowerCase();
    final pattern = switch (service) {
      SnsService.x => _x,
      SnsService.instagram => _instagram,
      SnsService.twitch => _twitch,
      SnsService.twitcasting => _twitcasting,
      SnsService.youtube => throw StateError('unreachable'),
    };
    return pattern.hasMatch(id) ? SnsAccountInput(service, id) : null;
  }

  static final _youtubeChannel = RegExp(r'^UC[A-Za-z0-9_-]{22}$');
  // YouTube のハンドルは3〜30文字で、英字以外の文字・数字・`_`・`-`・`.`・`·` を使える。
  static final _youtubeHandle = RegExp(
    r'^[\p{L}\p{M}\p{N}_.\-·]{3,30}$',
    unicode: true,
  );
  static final _x = RegExp(r'^[a-z0-9_]{1,15}$');
  static final _instagram = RegExp(r'^[a-z0-9._]{1,30}$');
  static final _twitch = RegExp(r'^[a-z0-9_]{3,25}$');
  static final _twitcasting = RegExp(r'^[a-z0-9_:]{1,100}$');

  // アカウントの名前と同じ形をしているが、アカウントのページではないパス。
  static const _xReserved = {
    'home',
    'explore',
    'search',
    'i',
    'settings',
    'messages',
    'notifications',
    'intent',
    'share',
    'hashtag',
    'compose',
    'login',
    'logout',
    'signup',
    'tos',
    'privacy',
    'about',
    'download',
    'jobs',
    'account',
    'lists',
  };
  static const _instagramReserved = {
    'p',
    'reel',
    'reels',
    'tv',
    'explore',
    'stories',
    'accounts',
    'direct',
    'about',
    'legal',
    'developer',
    'web',
    'challenge',
  };
  static const _twitchReserved = {
    'directory',
    'videos',
    'settings',
    'p',
    'search',
    'subscriptions',
    'inventory',
    'wallet',
    'drops',
    'downloads',
    'jobs',
    'turbo',
    'prime',
    'store',
    'friends',
    'messages',
    'payments',
    'popout',
    'moderator',
  };
}
