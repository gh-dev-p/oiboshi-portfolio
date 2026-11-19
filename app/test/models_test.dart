import 'dart:typed_data';

import 'package:oiboshi/data/services/common/image_upload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/creator_type.dart';
import 'package:oiboshi/domain/models/creator_settings.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/domain/models/oshi.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/report.dart';
import 'package:oiboshi/data/repositories/schedule/schedule_repository.dart';
import 'package:oiboshi/domain/models/schedule_filter.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/l10n/app_localizations.dart';
import 'package:oiboshi/ui/core/ui/l10n_labels.dart';
import 'package:oiboshi/domain/models/schedule_layout.dart';
import 'package:oiboshi/ui/schedule/widgets/time_grid.dart';
import 'package:oiboshi/utils/formatters.dart';
import 'package:oiboshi/utils/search_text.dart';

import 'fakes.dart';

import 'package:oiboshi/domain/models/creator_search.dart';

void main() {
  final now = DateTime(2026, 10, 14, 20, 10);
  final ja = lookupAppLocalizations(const Locale('ja'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('書式', () {
    // アプリでは flutter_localizations が読み込む、日付の書式のデータ。
    setUpAll(initializeDateFormatting);

    test('相対時刻', () {
      expect(
        relativeTime(
          now.subtract(const Duration(seconds: 30)),
          now: now,
          l10n: ja,
        ),
        'たった今',
      );
      expect(
        relativeTime(
          now.subtract(const Duration(minutes: 5)),
          now: now,
          l10n: ja,
        ),
        '5分前',
      );
      expect(
        relativeTime(
          now.subtract(const Duration(hours: 3)),
          now: now,
          l10n: ja,
        ),
        '3時間前',
      );
      expect(
        relativeTime(now.subtract(const Duration(days: 2)), now: now, l10n: ja),
        '2日前',
      );
      expect(
        relativeTime(DateTime(2026, 8, 1), now: now, l10n: ja),
        '2026/8/1',
      );
    });

    test('予定の日時は、今日・明日・日付で出す', () {
      expect(
        scheduleLabel(DateTime(2026, 10, 14, 21), now: now, l10n: ja),
        '今日 21:00',
      );
      expect(
        scheduleLabel(DateTime(2026, 10, 15, 12), now: now, l10n: ja),
        '明日 12:00',
      );
      expect(
        scheduleLabel(DateTime(2026, 10, 16, 22), now: now, l10n: ja),
        '10/16 22:00',
      );
    });

    test('残り時間と件数', () {
      expect(
        untilLabel(now.add(const Duration(minutes: 30)), now: now, l10n: ja),
        'まもなく',
      );
      expect(
        untilLabel(now.add(const Duration(hours: 3)), now: now, l10n: ja),
        'あと3時間',
      );
      expect(
        untilLabel(now.add(const Duration(days: 1)), now: now, l10n: ja),
        '明日',
      );
      expect(compactCount(9800, ja), '9,800');
      expect(compactCount(45200, ja), '4.5万');
      // 小数第1位が 0 なら省く（機能仕様書 4.2.5）。切り捨てなので、1.05万も「1万」。
      expect(compactCount(10000, ja), '1万');
      expect(compactCount(10500, ja), '1万');
      expect(compactCount(600000, ja), '60万');
      expect(compactCount(999999, ja), '99.9万');
      expect(compactCount(1234567, ja), '123万');
      // 1億以上は「◯.◯億」。万と同じく、切り捨てて、小数第1位が 0 なら省く。
      expect(compactCount(99999999, ja), '9999万');
      expect(compactCount(100000000, ja), '1億');
      expect(compactCount(123450000, ja), '1.2億');
      expect(compactCount(1099999999, ja), '10.9億');
      expect(compactCount(2000000000, ja), '20億');
      expect(longDate(DateTime(2026, 10, 14), ja), '10月14日（水）');
      expect(
        elapsed(
          now.subtract(const Duration(hours: 1, minutes: 5, seconds: 9)),
          now: now,
        ),
        '1:05:09',
      );
    });

    test('英語は、英語の書式で出す', () {
      expect(
        relativeTime(
          now.subtract(const Duration(minutes: 5)),
          now: now,
          l10n: en,
        ),
        '5m ago',
      );
      expect(
        relativeTime(DateTime(2026, 8, 1), now: now, l10n: en),
        '8/1/2026',
      );
      expect(
        scheduleLabel(DateTime(2026, 10, 15, 12), now: now, l10n: en),
        'Tomorrow 12:00',
      );
      expect(
        untilLabel(now.add(const Duration(hours: 3)), now: now, l10n: en),
        'In 3h',
      );
      expect(compactCount(45200, en), '45.2K');
      expect(longDate(DateTime(2026, 10, 14), en), 'Wed, Oct 14');
      expect(weekdayLabels(en).first, 'Mon');
    });
  });

  group('SNS の並び', () {
    test('どの画面でも YouTube・X・Instagram・ツイキャス・Twitch の順（画面定義書 5.1.7）', () {
      expect(SnsService.values, [
        SnsService.youtube,
        SnsService.x,
        SnsService.instagram,
        SnsService.twitcasting,
        SnsService.twitch,
      ]);
      expect(
        SnsService.ordered({
          SnsService.twitch,
          SnsService.x,
          SnsService.twitcasting,
        }),
        [SnsService.x, SnsService.twitcasting, SnsService.twitch],
      );
    });
  });

  group('新着', () {
    test('最後に見た時刻より新しく、3日以内なら新着', () {
      final follow = Follow(
        creatorId: 'minato',
        followedAt: now.subtract(const Duration(days: 10)),
        lastSeenAt: now.subtract(const Duration(hours: 2)),
      );
      expect(
        follow.isNew(now.subtract(const Duration(hours: 1)), now: now),
        isTrue,
      );
      expect(
        follow.isNew(now.subtract(const Duration(hours: 3)), now: now),
        isFalse,
      );
    });

    test('見ていなくても、3日より前の投稿は新着にしない', () {
      final follow = Follow(
        creatorId: 'minato',
        followedAt: now.subtract(const Duration(days: 10)),
      );
      expect(
        follow.isNew(now.subtract(const Duration(days: 4)), now: now),
        isFalse,
      );
      expect(
        follow.isNew(now.subtract(const Duration(days: 2)), now: now),
        isTrue,
      );
    });

    test('リングは、配信中・新着あり・既読の順に決まる', () {
      final live = Live(
        service: SnsService.twitcasting,
        title: 't',
        startedAt: now,
        playbackUrl: 'u',
        link: 'l',
        checkedAt: now,
      );
      final follow = Follow(
        creatorId: 'minato',
        followedAt: now.subtract(const Duration(days: 1)),
      );
      final recent = now.subtract(const Duration(hours: 1));
      expect(
        Oshi(
          follow: follow,
          creator: sampleCreator(live: live, latestPostAt: recent),
        ).ringAt(now),
        OshiRing.live,
      );
      expect(
        Oshi(
          follow: follow,
          creator: sampleCreator(latestPostAt: recent),
        ).ringAt(now),
        OshiRing.hasNew,
      );
      expect(
        Oshi(follow: follow, creator: sampleCreator()).ringAt(now),
        OshiRing.read,
      );
    });

    test('配信の確認が3分以上止まっていれば、配信中とみなさない', () {
      final live = Live(
        service: SnsService.youtube,
        title: 't',
        startedAt: now,
        playbackUrl: 'u',
        link: 'l',
        checkedAt: now.subtract(const Duration(minutes: 4)),
      );
      expect(sampleCreator(live: live).liveAt(now), isNull);
    });
  });

  group('予定', () {
    test('終了のない配信の予定は、1時間で描き、日に重なるかを判定する（機能仕様書 4.5.3）', () {
      final item = ScheduleItem(
        id: '1',
        creatorId: 'minato',
        title: '配信',
        startsAt: DateTime(2026, 10, 14, 23, 30),
        service: SnsService.youtube,
      );
      expect(item.displayEnd, DateTime(2026, 10, 15, 0, 30));
      expect(item.overlapsDay(DateTime(2026, 10, 14)), isTrue);
      expect(item.overlapsDay(DateTime(2026, 10, 15)), isTrue);
      expect(item.overlapsDay(DateTime(2026, 10, 16)), isFalse);
      expect(item.isPastAt(DateTime(2026, 10, 15, 1)), isTrue);
      expect(item.isLive, isTrue);
    });

    test('終日の予定は、その日だけに出る', () {
      final item = ScheduleItem(
        id: '1',
        creatorId: 'minato',
        title: 'ツアー告知',
        startsAt: DateTime(2026, 10, 14),
        allDay: true,
      );
      expect(item.overlapsDay(DateTime(2026, 10, 14)), isTrue);
      expect(item.overlapsDay(DateTime(2026, 10, 15)), isFalse);
      expect(item.isLive, isFalse);
    });

    test('終了のない予定は、イベントはその日の終わりまで、配信は1時間で描く（機能仕様書 4.5.3、2026-11-19 本人）', () {
      final creator = sampleCreator();
      final day = DateTime(2026, 10, 14);
      ScheduleItem at(String id, SnsService? service) => ScheduleItem(
        id: id,
        creatorId: 'minato',
        title: id,
        startsAt: DateTime(2026, 10, 14, 20),
        service: service,
      );
      final blocks = blocksFor(
        Oshi(
          follow: Follow(creatorId: 'minato', followedAt: now),
          creator: creator,
        ),
        [
          at('youtube', SnsService.youtube),
          at('twitch', SnsService.twitch),
          at('event', null),
        ],
        day,
        day,
      );
      expect(
        {for (final b in blocks) b.item!.id: b.end},
        {
          'youtube': DateTime(2026, 10, 14, 21),
          'twitch': DateTime(2026, 10, 14, 21),
          'event': DateTime(2026, 10, 15),
        },
      );
    });

    test('終了のないイベントは、その日の終わりまで続き、その日が終わったら過去（2026-11-19 本人）', () {
      final item = ScheduleItem(
        id: '1',
        creatorId: 'minato',
        title: 'ライブ',
        startsAt: DateTime(2026, 10, 14, 18),
      );
      expect(item.isEvent, isTrue);
      expect(item.displayEnd, DateTime(2026, 10, 15));
      expect(item.isPastAt(DateTime(2026, 10, 14, 23, 59)), isFalse);
      expect(item.isPastAt(DateTime(2026, 10, 15)), isTrue);
      expect(item.overlapsDay(DateTime(2026, 10, 14)), isTrue);
      expect(item.overlapsDay(DateTime(2026, 10, 15)), isFalse);
    });

    test('終日の予定は、その日のあいだは終わっていない', () {
      final item = ScheduleItem(
        id: '1',
        creatorId: 'minato',
        title: 'ツアー初日',
        startsAt: DateTime(2026, 10, 14),
        allDay: true,
      );
      final evening = DateTime(2026, 10, 14, 23, 59);
      final nextDay = DateTime(2026, 10, 15);
      expect(item.isPastAt(evening), isFalse);
      expect(item.hasEndedAt(evening), isFalse);
      expect(item.isPastAt(nextDay), isTrue);
      expect(item.hasEndedAt(nextDay), isTrue);
    });

    test('イベントの終わりは、終了時刻（なければ開始）で決める', () {
      final ongoing = ScheduleItem(
        id: '1',
        creatorId: 'minato',
        title: '展示',
        startsAt: DateTime(2026, 10, 1, 10),
        endsAt: DateTime(2026, 10, 31, 18),
      );
      expect(ongoing.hasEndedAt(DateTime(2026, 10, 3)), isFalse);
      expect(ongoing.hasEndedAt(DateTime(2026, 10, 31, 18)), isTrue);
      final noEnd = ScheduleItem(
        id: '2',
        creatorId: 'minato',
        title: 'ライブ',
        startsAt: DateTime(2026, 10, 14, 18),
      );
      expect(noEnd.hasEndedAt(DateTime(2026, 10, 14, 17, 59)), isFalse);
      expect(noEnd.hasEndedAt(DateTime(2026, 10, 14, 18)), isTrue);
    });

    test('配信中なら、予定がなくても配信中のブロックを作る', () {
      final live = Live(
        service: SnsService.twitcasting,
        title: '雑談',
        startedAt: now.subtract(const Duration(minutes: 30)),
        playbackUrl: 'u',
        link: 'l',
        checkedAt: now,
      );
      final oshi = Oshi(
        follow: Follow(creatorId: 'minato', followedAt: now),
        creator: sampleCreator(live: live),
      );
      final blocks = blocksFor(oshi, const [], dateOnly(now), now);
      expect(blocks, hasLength(1));
      expect(blocks.first.isLiveNow, isTrue);
      expect(blocks.first.openEnded, isTrue);
      expect(blocks.first.end, now);
      expect(blocks.first.title, '雑談');
    });

    test('予定と配信が同じサービスで重なれば、その予定を配信中にする', () {
      final live = Live(
        service: SnsService.twitcasting,
        title: '雑談',
        startedAt: now.subtract(const Duration(minutes: 30)),
        playbackUrl: 'u',
        link: 'l',
        checkedAt: now,
      );
      final oshi = Oshi(
        follow: Follow(creatorId: 'minato', followedAt: now),
        creator: sampleCreator(live: live),
      );
      final item = ScheduleItem(
        id: '1',
        creatorId: 'minato',
        title: '夜の雑談配信',
        startsAt: now.subtract(const Duration(minutes: 40)),
        service: SnsService.twitcasting,
      );
      final blocks = blocksFor(oshi, [item], dateOnly(now), now);
      expect(blocks, hasLength(1));
      expect(blocks.first.isLiveNow, isTrue);
      expect(blocks.first.item, same(item));
    });

    test('終わった配信（実績）を、予定と同じ形で読む。タイトルが空なら「配信」', () {
      final item = ScheduleItem.fromLiveRecord({
        'creator_id': 'minato',
        'service': 'youtube',
        'live_id': 'v1',
        'title': ' ',
        'started_at': '2026-10-14T03:00:00Z',
        'ended_at': '2026-10-14T05:00:00Z',
      });
      expect(item.id, 'record:youtube:v1');
      expect(item.title, '');
      expect(ja.scheduleTitle(item), '配信');
      expect(en.scheduleTitle(item), 'Live');
      expect(item.isLive, isTrue);
      expect(item.endsAt, DateTime.utc(2026, 10, 14, 5).toLocal());
    });

    test('終わった配信は、実際の開始から終了までの、終わったブロックになる', () {
      final oshi = Oshi(
        follow: Follow(creatorId: 'minato', followedAt: now),
        creator: sampleCreator(),
      );
      final record = ScheduleItem(
        id: 'record:youtube:v1',
        creatorId: 'minato',
        title: '朝の配信',
        startsAt: now.subtract(const Duration(hours: 3)),
        endsAt: now.subtract(const Duration(hours: 1)),
        service: SnsService.youtube,
      );
      final blocks = blocksFor(oshi, [record], dateOnly(now), now);
      expect(blocks, hasLength(1));
      expect(blocks.first.isLiveNow, isFalse);
      expect(blocks.first.openEnded, isFalse);
      expect(blocks.first.end, record.endsAt);
      expect(blocks.first.isPastAt(now), isTrue);
    });
  });

  group('予定の絞り込みと実績', () {
    Oshi liveOshi(SnsService service) => Oshi(
      follow: Follow(creatorId: 'minato', followedAt: now),
      creator: sampleCreator(
        live: Live(
          service: service,
          title: '雑談',
          startedAt: now.subtract(const Duration(minutes: 30)),
          playbackUrl: 'u',
          link: 'l',
          checkedAt: now,
        ),
      ),
    );

    test('イベントの公演は、「イベント」のチップだけで出し入れする', () {
      ScheduleItem at(String id, SnsService? service) => ScheduleItem(
        id: id,
        creatorId: 'minato',
        title: id,
        startsAt: now,
        service: service,
      );
      final performance = at('performance', null);
      final live = at('live', SnsService.youtube);
      const ids = {'minato'};
      bool shows(ScheduleFilter f, ScheduleItem s) => f.showsSchedule(s, ids);

      expect(shows(const ScheduleFilter(), performance), isTrue);
      expect(
        shows(const ScheduleFilter(showPlatformless: false), performance),
        isFalse,
      );
      // SNS だけを外しても、公演は残る。
      expect(shows(const ScheduleFilter(services: {}), performance), isTrue);
      // 「配信」のスイッチは、公演には効かない。
      expect(shows(const ScheduleFilter(showLive: false), performance), isTrue);
      expect(shows(const ScheduleFilter(showLive: false), live), isFalse);
      // 「イベント」のチップは、プラットフォームのある予定には効かない。
      expect(
        shows(const ScheduleFilter(showPlatformless: false), live),
        isTrue,
      );
      // 比べる・ハッシュにも入れる（Provider のキー）。
      expect(
        const ScheduleFilter(showPlatformless: false),
        isNot(const ScheduleFilter()),
      );
      expect(
        const ScheduleFilter().copyWith(showPlatformless: false),
        const ScheduleFilter(showPlatformless: false),
      );
      expect(
        const ScheduleFilter(showPlatformless: false).hashCode,
        const ScheduleFilter(showPlatformless: false).hashCode,
      );
    });

    test('予約のない配信中の配信も、「配信」のスイッチとプラットフォームに従う', () {
      final oshi = liveOshi(SnsService.twitcasting);
      final day = dateOnly(now);
      expect(blocksFor(oshi, const [], day, now), hasLength(1));
      expect(
        blocksFor(
          oshi,
          const [],
          day,
          now,
          filter: const ScheduleFilter(showLive: false),
        ),
        isEmpty,
      );
      expect(
        blocksFor(
          oshi,
          const [],
          day,
          now,
          filter: const ScheduleFilter(services: {SnsService.youtube}),
        ),
        isEmpty,
      );
      expect(
        blocksFor(
          oshi,
          const [],
          day,
          now,
          filter: const ScheduleFilter(services: {SnsService.twitcasting}),
        ),
        hasLength(1),
      );
    });

    test('外した推しだけを隠し、あとからフォローした推しは出す。出す推しがいなければ全員', () {
      const filter = ScheduleFilter(hiddenCreatorIds: {'a', 'gone'});
      // 'gone'（フォローを外した推し）は数えない。'c' は、あとからフォローした推し。
      expect(filter.shownCreatorIds(['a', 'b', 'c']), {'b', 'c'});
      expect(filter.shownCreatorIds(['a']), {'a'});
      expect(const ScheduleFilter().shownCreatorIds(['a', 'b']), {'a', 'b'});
    });

    test('取得した予約は、external_id を持つ行', () {
      Map<String, dynamic> row({String? externalId}) => {
        'id': 's1',
        'creator_id': 'minato',
        'title': '配信',
        'starts_at': '2026-10-14T12:00:00Z',
        'service': 'youtube',
        'external_id': externalId,
      };
      expect(ScheduleItem.fromRow(row(externalId: 'v1')).fetched, isTrue);
      expect(ScheduleItem.fromRow(row()).fetched, isFalse);
    });

    test('同じ発信者・サービスの実績が、開始予定の30分前から12時間後までに始まっていたら、取得した予約を出さない', () {
      final start = DateTime(2026, 10, 14, 21);
      ScheduleItem reservation(
        String id, {
        bool fetched = true,
        SnsService service = SnsService.youtube,
        String creatorId = 'minato',
      }) => ScheduleItem(
        id: id,
        creatorId: creatorId,
        title: id,
        startsAt: start,
        service: service,
        fetched: fetched,
      );
      ScheduleItem record(DateTime startedAt) => ScheduleItem(
        id: 'record:youtube:$startedAt',
        creatorId: 'minato',
        title: '',
        startsAt: startedAt,
        endsAt: startedAt.add(const Duration(hours: 1)),
        service: SnsService.youtube,
      );
      List<String> shown(List<ScheduleItem> records) => [
        for (final s in ScheduleRepository.withoutRecordedReservations([
          reservation('fetched'),
          reservation('manual', fetched: false),
          reservation('twitch', service: SnsService.twitch),
          reservation('other', creatorId: 'sora'),
        ], records))
          s.id,
      ];
      // 早めに始めた配信も、遅れて始めた配信も、その予約の配信とみなす。
      expect(shown([record(start.subtract(const Duration(minutes: 30)))]), [
        'manual',
        'twitch',
        'other',
      ]);
      expect(shown([record(start.add(const Duration(hours: 11)))]), [
        'manual',
        'twitch',
        'other',
      ]);
      // 時間帯の外の実績は、別の配信。
      expect(shown([record(start.subtract(const Duration(minutes: 31)))]), [
        'fetched',
        'manual',
        'twitch',
        'other',
      ]);
      expect(shown([record(start.add(const Duration(hours: 12)))]), [
        'fetched',
        'manual',
        'twitch',
        'other',
      ]);
    });
  });

  group('投稿', () {
    test('30分以内の投稿は「+N」にまとめる', () {
      final posts = [
        samplePost(id: 'a', postedAt: now),
        samplePost(id: 'b', postedAt: now.add(const Duration(minutes: 20))),
        samplePost(id: 'c', postedAt: now.add(const Duration(hours: 2))),
      ];
      final clusters = clusterPosts(posts);
      expect(clusters, hasLength(2));
      expect(clusters.first.isGroup, isTrue);
      expect(clusters.first.posts.first.id, 'b');
      expect(clusters.last.isGroup, isFalse);
    });

    test('サムネイルの縦横比', () {
      expect(samplePost(kind: PostKind.short).thumbnailAspectRatio, 9 / 16);
      expect(samplePost().thumbnailAspectRatio, 16 / 9);
      expect(
        samplePost(
          source: SnsService.instagram,
          kind: PostKind.image,
        ).thumbnailAspectRatio,
        1,
      );
    });
  });

  test('合計フォロワー数は、いちばん粗い丸め（YouTube は上から3桁）の桁で切り捨てる', () {
    Creator withCounts(Map<SnsService, int> counts) =>
        Creator(id: 'c', name: 'c', followerCounts: counts);
    expect(
      withCounts({
        SnsService.youtube: 525000,
        SnsService.instagram: 62961,
      }).totalFollowers,
      587000,
    );
    expect(
      withCounts({
        SnsService.youtube: 1230,
        SnsService.instagram: 3813,
      }).totalFollowers,
      5040,
    );
    // 1,000 未満の YouTube と、丸めていない SNS は、そのまま足す。
    expect(
      withCounts({
        SnsService.youtube: 562,
        SnsService.instagram: 3813,
      }).totalFollowers,
      4375,
    );
    expect(
      withCounts({
        SnsService.twitch: 1225822,
        SnsService.x: 250137,
      }).totalFollowers,
      1475959,
    );
    expect(withCounts({}).totalFollowers, isNull);
  });

  test('名前または ID で絞り込む', () {
    final creators = [sampleCreator(), const Creator(id: 'rei', name: '月城レイ')];
    expect(filterCreators(creators, 'ミナト').map((c) => c.id), ['minato']);
    expect(filterCreators(creators, 'REI').map((c) => c.id), ['rei']);
    expect(filterCreators(creators, ''), hasLength(2));
    expect(filterCreators(creators, 'ほしのミナ'), isEmpty);
    // SNS のアカウント（確認済みのもの）と、先頭の @。
    expect(filterCreators(creators, 'minato_x').map((c) => c.id), ['minato']);
    expect(filterCreators(creators, '@rei').map((c) => c.id), ['rei']);
    expect(filterCreators(creators, '@'), hasLength(2));
    // 先頭に続く @ は、すべて外す（サーバーの検索と同じ）。
    expect(filterCreators(creators, '@@minato').map((c) => c.id), ['minato']);
    // 全角と半角、ひらがなとカタカナは、同じ字とみなす。
    expect(filterCreators(creators, 'みなと').map((c) => c.id), ['minato']);
    expect(filterCreators(creators, 'ﾐﾅﾄ').map((c) => c.id), ['minato']);
    expect(filterCreators(creators, 'ＲＥＩ').map((c) => c.id), ['rei']);
  });

  test('確認前の SNS のアカウントでは探せない', () {
    const creator = Creator(
      id: 'sora',
      name: '空',
      linkedAccounts: {
        SnsService.x: CreatorAccount(service: SnsService.x, account: 'sora_x'),
      },
    );
    expect(filterCreators([creator], 'sora_x'), isEmpty);
  });

  test('確認済みの YouTube のハンドルで探せる', () {
    const creator = Creator(
      id: 'sora',
      name: '空',
      linkedAccounts: {
        SnsService.youtube: CreatorAccount(
          service: SnsService.youtube,
          account: 'UCsora',
          verified: true,
          handle: 'ソラch',
        ),
      },
    );
    expect(filterCreators([creator], '@そらCH').map((c) => c.id), ['sora']);
  });

  test('検索の表記の揺れをそろえる', () {
    expect(normalizeForSearch('ガギグ'), 'がぎぐ');
    expect(normalizeForSearch('ｶﾞｷﾞｸﾞ ﾊﾟﾋﾟ ｳﾞ'), 'がぎぐ ぱぴ ゔ');
    expect(normalizeForSearch('Ａｂｃ１２３＿　ｰ'), 'abc123_ ー');
    expect(normalizeForSearch('ﾐﾅﾄｰ'), 'みなとー');
  });

  test('発信者のタイプと、タイプの一覧を読む', () {
    final creator = Creator.fromRow({
      'id': 'a',
      'name': 'a',
      'types': ['game', 'chat'],
    });
    expect(creator.types, ['game', 'chat']);
    expect(Creator.fromRow({'id': 'b', 'name': 'b'}).types, isEmpty);
    final type = CreatorType.fromRow({
      'id': 'game',
      'name': 'ゲーム',
      'name_en': 'Games',
      'position': 10,
    });
    expect((type.id, type.name, type.nameEn), ('game', 'ゲーム', 'Games'));
  });

  test('アプリ運営用ログインは、5回続けて違ったら5分のあいだ入れない', () {
    final now = DateTime.utc(2026, 11, 11, 12);
    var lock = const PasswordLoginLock();
    for (var i = 1; i < PasswordLoginLock.maxFailures; i++) {
      lock = lock.failedAt(now);
      expect((lock.failures, lock.lockedAt(now)), (i, false));
    }
    lock = lock.failedAt(now);
    expect(lock.failures, 0);
    expect(lock.lockedAt(now.add(const Duration(minutes: 4))), isTrue);
    expect(lock.lockedAt(now.add(const Duration(minutes: 5))), isFalse);
  });

  test('この版で出さない SNS（v1.0.0 のツイキャス）は、アカウント・フォロワー数・配信を読まない', () {
    final creator = Creator.fromRow({
      'id': 'kumo',
      'name': 'クモ',
      'creator_accounts': [
        {
          'service': 'twitcasting',
          'account': 'kumo_tc',
          'verified_at': '2026-10-14T00:00:00Z',
        },
      ],
      'follower_counts': {'youtube': 100, 'twitcasting': 50},
      'lives': {
        'service': 'twitcasting',
        'title': 'live',
        'started_at': '2026-10-14T10:00:00Z',
        'playback_url': 'https://example.com/live.m3u8',
        'link': 'https://twitcasting.tv/kumo_tc',
        'checked_at': '2026-10-14T10:01:00Z',
      },
    });
    expect(
      creator.accounts,
      twitcastingOffered ? {SnsService.twitcasting: 'kumo_tc'} : isEmpty,
    );
    expect(creator.totalFollowers, twitcastingOffered ? 150 : 100);
    expect(
      creator.live?.service,
      twitcastingOffered ? SnsService.twitcasting : isNull,
    );
  });

  test('取得した予約と実績は、この版で出さない SNS なら出さない。手で登録した予定は出す', () {
    ScheduleItem item(
      SnsService service, {
      bool fetched = false,
      bool record = false,
    }) => ScheduleItem(
      id: service.name,
      creatorId: 'minato',
      title: '',
      startsAt: DateTime.utc(2026, 11, 11),
      service: service,
      fetched: fetched,
      record: record,
    );
    for (final service in SnsService.values) {
      expect(item(service, fetched: true).offered, service.offered);
      expect(item(service, record: true).offered, service.offered);
      expect(item(service).offered, isTrue);
    }
    expect(SnsService.twitcasting.offered, twitcastingOffered);
  });

  test('サーバーの行から発信者を読む', () {
    final creator = Creator.fromRow({
      'id': 'kumo',
      'name': 'クモ',
      'bio': 'hi',
      'creator_accounts': [
        {
          'service': 'youtube',
          'account': 'UCx',
          'verified_at': '2026-10-14T00:00:00Z',
        },
        {'service': 'instagram', 'account': 'kumo_ig', 'verified_at': null},
        {
          'service': 'tiktok',
          'account': 'unknown',
          'verified_at': '2026-10-14T00:00:00Z',
        },
      ],
      'follower_counts': {'youtube': 100, 'instagram': 50},
      'x_option': true,
      'lives': {
        'service': 'youtube',
        'title': 'live',
        'started_at': '2026-10-14T10:00:00Z',
        'playback_url': 'https://www.youtube.com/embed/x',
        'link': 'https://youtube.com/watch?v=x',
        'checked_at': '2026-10-14T10:01:00Z',
      },
    });
    // 追星に出すのは、確認済みのアカウントだけ。知らない SNS の行は読まない。
    // この版で出さない SNS（v1.0.0 の Instagram）の行とフォロワー数も読まない。
    expect(creator.accounts, {SnsService.youtube: 'UCx'});
    expect(creator.linkedAccounts.keys, [
      SnsService.youtube,
      if (instagramOffered) SnsService.instagram,
    ]);
    expect(
      creator.linkedAccounts[SnsService.instagram]?.verified,
      instagramOffered ? isFalse : isNull,
    );
    expect(creator.xOption, isTrue);
    expect(creator.totalFollowers, instagramOffered ? 150 : 100);
    expect(creator.live?.usesEmbed, isTrue);
  });

  test('時間軸の位置は、選んだ日の0時から数える', () {
    final day = DateTime(2026, 10, 10);
    // 選んだ日の 21:30 は、21.5 時間ぶん下。今日がいつでも変わらない。
    expect(TimeGrid.offsetOf(DateTime(2026, 10, 10, 21, 30), day, 10), 215);
    expect(TimeGrid.offsetOf(DateTime(2026, 10, 10), day, 10), 0);
    // その日より前は 0、後は 24時の位置に寄せる（日をまたぐ予定）。
    expect(TimeGrid.offsetOf(DateTime(2026, 10, 9, 23), day, 10), 0);
    expect(TimeGrid.offsetOf(DateTime(2026, 10, 11, 1), day, 10), 240);
  });

  test('取り込んだアイコンの画像の種類を、先頭のバイトから決める', () {
    expect(
      imageContentType(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0])),
      'image/png',
    );
    expect(
      imageContentType(
        Uint8List.fromList([
          0x52,
          0x49,
          0x46,
          0x46,
          0,
          0,
          0,
          0,
          0x57,
          0x45,
          0x42,
          0x50,
        ]),
      ),
      'image/webp',
    );
    expect(
      imageContentType(Uint8List.fromList([0x47, 0x49, 0x46, 0x38])),
      'image/gif',
    );
    expect(
      imageContentType(Uint8List.fromList([0xFF, 0xD8, 0xFF])),
      'image/jpeg',
    );
  });

  test('連携と取り戻しの結果を、サーバーの文字列から引く', () {
    expect(
      AccountLinkResult.fromServer('reclaimable'),
      AccountLinkResult.reclaimable,
    );
    expect(ReclaimResult.fromServer('reclaimed'), ReclaimResult.reclaimed);
    // 基本プランを無料にしたので、サーバーは not_subscribed を返さない。古い値は失敗として扱う。
    expect(ReclaimResult.fromServer('not_subscribed'), ReclaimResult.failed);
    expect(
      ReclaimResult.fromServer('not_reclaimable'),
      ReclaimResult.notReclaimable,
    );
    expect(ReclaimResult.fromServer('already_owner'), ReclaimResult.failed);
    final row = ReclaimableCreator.fromRow({
      'id': 'c1',
      'name': '発信者',
      'avatar_url': null,
      'purge_at': '2026-12-01T00:00:00+00:00',
    });
    expect(row.purgeAt, DateTime.utc(2026, 12, 1).toLocal());
  });

  test('発信者の登録の結果を、サーバーの文字列から引く', () {
    expect(RegisterResult.fromServer('registered'), RegisterResult.registered);
    expect(RegisterResult.fromServer('not_subscribed'), RegisterResult.failed);
    expect(
      RegisterResult.fromServer('registration_closed'),
      RegisterResult.closed,
    );
    expect(RegisterResult.fromServer('no_links'), RegisterResult.failed);
    expect(RegisterResult.fromServer(null), RegisterResult.failed);
  });

  test('通報の結果は、受け付けた・通報済みのほかを、送れなかったとする', () {
    expect(ReportResult.fromServer('submitted'), ReportResult.submitted);
    expect(ReportResult.fromServer('duplicate'), ReportResult.duplicate);
    expect(ReportResult.fromServer('not_found'), ReportResult.failed);
    expect(ReportResult.fromServer(null), ReportResult.failed);
    expect(ReportReason.dangerousLink.serverName, 'dangerous_link');
  });

  test('イベントの公演は、イベントに属する予定だけで、取得した予約と、終わった配信を含まない', () {
    final start = DateTime(2026, 10, 16, 12);
    expect(
      ScheduleItem(
        id: 's1',
        creatorId: 'c',
        title: 't',
        startsAt: start,
        eventId: 'e1',
      ).isEventPerformance,
      isTrue,
    );
    expect(
      ScheduleItem(
        id: 's2',
        creatorId: 'c',
        title: 't',
        startsAt: start,
        fetched: true,
      ).isEventPerformance,
      isFalse,
    );
    expect(
      ScheduleItem.fromLiveRecord({
        'service': 'youtube',
        'live_id': 'v1',
        'creator_id': 'c',
        'started_at': '2026-10-16T03:00:00Z',
      }).isEventPerformance,
      isFalse,
    );
  });

  test('停止中かを、ビューの行から読む', () {
    expect(
      Creator.fromRow({'id': 'c', 'name': 'n', 'suspended': true}).suspended,
      isTrue,
    );
    expect(Creator.fromRow({'id': 'c', 'name': 'n'}).suspended, isFalse);
  });

  test('投稿の生配信の印（live_status）があれば、生配信の枠とみなす', () {
    Map<String, dynamic> row(String? liveStatus) => {
      'id': 'yt:1',
      'creator_id': 'minato',
      'source': 'youtube',
      'kind': 'video',
      'posted_at': '2026-11-18T00:00:00Z',
      'permalink': 'https://youtu.be/1',
      'live_status': liveStatus,
    };
    expect(Post.fromRow(row('live')).isLiveContent, isTrue);
    expect(Post.fromRow(row('upcoming')).isLiveContent, isTrue);
    expect(Post.fromRow(row(null)).isLiveContent, isFalse);
  });
}
