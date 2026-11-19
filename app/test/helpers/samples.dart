import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/sns_service.dart';

/// X連携プランに加入中の状態。
PlanSubscription subscribed({bool willRenew = true}) => PlanSubscription(
  xOption: true,
  expiresAt: DateTime(2026, 11, 14),
  willRenew: willRenew,
);

/// 今日のうちの、いまより後の時刻。ホームの「次の予定」は本日中の予定だけを出すので、日をまたがない時刻を使う。
/// いまから今日の終わりまでを [of] + 1 等分し、[n] 番目（1から）の位置を返す。
DateTime laterToday(int n, {int of = 1}) {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day + 1);
  return now.add(end.difference(now) * n ~/ (of + 1));
}

/// よく使う発信者。
Creator sampleCreator({Live? live, DateTime? latestPostAt}) => Creator(
  id: 'minato',
  name: '星野ミナト',
  bio: '歌とゲームの配信をしています',
  linkedAccounts: const {
    SnsService.youtube: CreatorAccount(
      service: SnsService.youtube,
      account: 'UC123',
      verified: true,
    ),
    SnsService.x: CreatorAccount(
      service: SnsService.x,
      account: 'minato_x',
      verified: true,
    ),
  },
  followerCounts: const {SnsService.youtube: 45200},
  live: live,
  latestPostAt: latestPostAt,
);

/// よく使う投稿。[permalink] を省くと、[id] から作る。
Post samplePost({
  String id = 'yt:1',
  String creatorId = 'minato',
  SnsService source = SnsService.youtube,
  PostKind kind = PostKind.video,
  String text = '新しい動画',
  DateTime? postedAt,
  int? viewCount,
  int? likeCount,
  int? commentCount,
  String? permalink,
  String? thumbnailUrl,
  String? videoUrl,
  List<PostMedia> media = const [],
  bool isLiveContent = false,
}) => Post(
  id: id,
  creatorId: creatorId,
  source: source,
  kind: kind,
  text: text,
  postedAt: postedAt ?? DateTime.now().subtract(const Duration(hours: 1)),
  permalink: permalink ?? 'https://example.com/$id',
  thumbnailUrl: thumbnailUrl,
  videoUrl: videoUrl,
  media: media,
  viewCount: viewCount,
  likeCount: likeCount,
  commentCount: commentCount,
  isLiveContent: isLiveContent,
);

/// よく使う配信中の情報。5分前に始まり、いま確かめた配信。
Live sampleLive({
  SnsService service = SnsService.twitcasting,
  String title = '朝の雑談',
  String playbackUrl = 'https://example.com/live.m3u8',
  String link = 'https://twitcasting.tv/minato',
  DateTime? startedAt,
  DateTime? checkedAt,
}) => Live(
  service: service,
  title: title,
  startedAt: startedAt ?? DateTime.now().subtract(const Duration(minutes: 5)),
  playbackUrl: playbackUrl,
  link: link,
  checkedAt: checkedAt ?? DateTime.now(),
);

/// タイトルで見分ける配信中の情報。再生の URL とリンクにも、タイトルを入れる。
Live liveTitled(
  String title, {
  SnsService service = SnsService.twitcasting,
  String? link,
}) => sampleLive(
  service: service,
  title: title,
  playbackUrl: 'https://example.com/$title.m3u8',
  link: link ?? 'https://twitcasting.tv/$title',
);

/// いまフォローした推し。
Follow sampleFollow([String creatorId = 'minato']) =>
    Follow(creatorId: creatorId, followedAt: DateTime.now());

/// 2人目の発信者。
Creator hiyori({Live? live}) =>
    Creator(id: 'hiyori', name: '桜井ひより', live: live);

/// Apple で結び付けたログイン方法。
const appleLogin = LoginMethod(
  provider: LoginProvider.apple,
  identityId: 'apple',
);

/// Google で結び付けたログイン方法。
const googleLogin = LoginMethod(
  provider: LoginProvider.google,
  identityId: 'google',
);

/// 予定。発信者を省くと、[sampleCreator] の予定にする。
ScheduleItem sampleSchedule(
  String id,
  String title,
  DateTime startsAt, {
  String creatorId = 'minato',
  DateTime? endsAt,
  bool allDay = false,
  SnsService? service,
  String? venue,
  String? ticketUrl,
  bool ticketIsPromotion = false,
  bool fetched = false,
  String? externalId,
  bool record = false,
  String? eventId,
  String? performanceUrl,
}) => ScheduleItem(
  id: id,
  creatorId: creatorId,
  title: title,
  startsAt: startsAt,
  endsAt: endsAt,
  allDay: allDay,
  service: service,
  venue: venue,
  ticketUrl: ticketUrl,
  ticketIsPromotion: ticketIsPromotion,
  externalId: externalId,
  fetched: fetched,
  record: record,
  // 発信者が手で作れる予定は、イベントの公演だけ（データ設計書 3.1.16）。プラットフォームのない予定は、公演にする。
  eventId:
      eventId ?? (service == null && !fetched && !record ? 'ev_$id' : null),
  performanceUrl: performanceUrl,
);
