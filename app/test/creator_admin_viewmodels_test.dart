import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/creator_settings.dart';
import 'package:oiboshi/domain/models/event_draft.dart';
import 'package:oiboshi/domain/models/event.dart';
import 'package:oiboshi/domain/models/event_url_key.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';
import 'package:oiboshi/domain/models/schedule_item.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/creator_admin/view_models/account_link_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/event_manage_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/creator_admin_providers.dart';
import 'package:oiboshi/ui/creator_admin/view_models/creator_menu_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/creator_register_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/display_contents_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/event_candidates_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/event_register_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/schedule_input.dart';
import 'package:oiboshi/ui/creator_admin/view_models/plan_viewmodel.dart';
import 'package:oiboshi/ui/creator_admin/view_models/profile_edit_viewmodel.dart';
import 'package:oiboshi/ui/settings/view_models/settings_providers.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

/// 発信者向けの画面の ViewModel。Repository は [FakeData] を読み書きするフェイクに差し替える。
void main() {
  late FakeData data;
  late ProviderContainer container;

  setUp(() async {
    data = FakeData()..creators.add(sampleCreator());
    container = await testContainer(data);
  });

  group('イベントの登録', () {
    const pia = 'https://t.pia.jp/pia/event/event.do?eventBundleCd=b1';

    test('同じチケットのページを指すリンクが2本あれば、1本にして保存する（PR はどちらかが PR なら PR）', () async {
      final vm = container.read(
        eventRegisterViewModelProvider('minato').notifier,
      );
      final error = await vm.save(
        EventRegisterInput(
          title: 'ツアー',
          links: const [
            LinkInput(url: pia),
            LinkInput(url: '$pia&utm_source=x', promotion: true),
            LinkInput(url: 'https://eplus.jp/sf/detail/0000000001'),
          ],
          performance: PerformanceInput(
            date: DateTime(2026, 11, 2),
            start: const TimeOfDay(hour: 18, minute: 0),
          ),
        ),
      );
      expect(error, isNull);
      expect(
        [
          for (final l in data.events.values.single.links)
            (l.url, l.isPromotion),
        ],
        [(pia, true), ('https://eplus.jp/sf/detail/0000000001', false)],
      );
    });

    test('日付の選択の範囲は、入っている日付が外にあれば、そこまで広げる', () {
      final now = DateTime(2026, 10, 30, 12);
      final (first, last) = scheduleDateRange(null, now: now);
      expect(first, DateTime(2025, 10, 30));
      expect(last, DateTime(2028, 10, 29));
      final old = DateTime(2024, 5, 1, 19);
      expect(scheduleDateRange(old, now: now).$1, DateTime(2024, 5, 1));
      final far = DateTime(2030, 1, 1);
      expect(scheduleDateRange(far, now: now).$2, far);
    });

    test('リンクの鍵は、サーバーの event_url_key と同じ形にする', () {
      expect(eventUrlKey(pia), 'pia:bundle:b1');
      expect(
        eventUrlKey(
          'https://t.pia.jp/pia/ticketInformation.do?eventCd=1234567&rlsCd=002',
        ),
        'pia:event:1234567:002',
      );
      expect(
        eventUrlKey('https://eplus.jp/sf/detail/0000000001-P0030001'),
        'eplus:0000000001-p0030001',
      );
      expect(eventUrlKey('https://zaiko.io/e/abc?x=1'), 'zaiko:abc');
      expect(
        eventUrlKey('https://www.Example.com/a/?utm_source=x&b=1#top'),
        'example.com/a?b=1',
      );
      expect(
        uniqueEventLinks(const [
          EventLink(url: 'https://example.com/a'),
          EventLink(url: 'https://example.com/a/'),
        ]).length,
        1,
      );
    });
  });

  group('公演の候補', () {
    const url = 'https://t.pia.jp/pia/ticketInformation.do?eventCd=1';
    final group = PerformanceGroup(
      date: DateTime(2026, 11, 2),
      venue: 'Zepp Nagoya',
      tickets: const [
        TicketOption(site: TicketSite.pia, url: url, eventTitle: ''),
      ],
    );

    test('イベントの名前もページのタイトルも取れなければ、保存せずに下書きを返す', () async {
      final key = EventCandidatesKey('minato', const [url]);
      final vm = container.read(eventCandidatesViewModelProvider(key).notifier);
      final result = await vm.registerPerformance(
        group,
        group.tickets.first,
        '',
      );
      expect(result, isA<CandidateNeedsInput>());
      final draft = (result as CandidateNeedsInput).draft!;
      expect(draft.title, isNull);
      expect(draft.performances.single.venue, 'Zepp Nagoya');
      expect(draft.performances.single.url, url);
      expect(data.events, isEmpty);
    });
  });

  group('イベントの管理', () {
    ScheduleItem event(
      String id,
      DateTime startsAt, {
      DateTime? endsAt,
      bool allDay = false,
      String? externalId,
    }) => ScheduleItem.fromRow({
      'id': id,
      'creator_id': 'minato',
      'title': id,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'all_day': allDay,
      'external_id': externalId,
      'event_id': externalId == null ? 'ev_$id' : null,
    });

    test('これからの公演は古い順、過去の公演（終わった公演）は新しい順に分ける', () {
      final now = DateTime(2026, 10, 20, 12);
      final state = EventManageViewModel.split([
        event('next_week', DateTime(2026, 10, 27, 20)),
        event('tomorrow', DateTime(2026, 10, 21, 20)),
        // 今日の終日の予定は、これから。昨日の終日の予定は、過去。
        event('today_all_day', DateTime(2026, 10, 20), allDay: true),
        event('yesterday_all_day', DateTime(2026, 10, 19), allDay: true),
        // 終了のない公演は、その日が終わるまではこれから。前の日のものは過去（2026-11-19 本人）。
        event('started', DateTime(2026, 10, 20, 11, 30)),
        event('this_morning', DateTime(2026, 10, 20, 8)),
        event('ended', DateTime(2026, 10, 19, 22)),
        // 終了のある予定は、終了で決める。
        event(
          'long',
          DateTime(2026, 10, 20, 9),
          endsAt: DateTime(2026, 10, 20, 13),
        ),
        event(
          'last_month',
          DateTime(2026, 9, 20, 18),
          endsAt: DateTime(2026, 9, 20, 20),
        ),
      ], now: now);
      expect(state.upcoming.map((s) => s.id), [
        'today_all_day',
        'this_morning',
        'long',
        'started',
        'tomorrow',
        'next_week',
      ]);
      expect(state.past.map((s) => s.id), [
        'ended',
        'yesterday_all_day',
        'last_month',
      ]);
    });

    test('取得した配信の予約は、一覧に出さない', () async {
      data.schedules.addAll([
        event('mine', DateTime(2099, 1, 1, 20)),
        event('fetched', DateTime(2099, 1, 2, 20), externalId: 'yt:1'),
      ]);
      final state = await container.read(
        eventManageViewModelProvider('minato').future,
      );
      expect(state.upcoming.map((s) => s.id), ['mine']);
      expect(state.past, isEmpty);
    });
  });

  group('プロフィールの編集', () {
    test('名前が空か長すぎると保存せず、保存できたら発信者を読み直す', () async {
      final sub = container.listen(
        profileEditViewModelProvider('minato'),
        (_, _) {},
      );
      await container.read(profileEditViewModelProvider('minato').future);
      final vm = container.read(
        profileEditViewModelProvider('minato').notifier,
      );
      expect(
        await vm.save(name: ' ', bio: '', types: const []),
        ProfileSaveError.nameInvalid,
      );
      expect(
        await vm.save(name: 'あ' * 101, bio: '', types: const []),
        ProfileSaveError.nameInvalid,
      );
      expect(
        await vm.save(name: ' 新しい名前 ', bio: ' 自己紹介 ', types: const ['game']),
        isNull,
      );
      expect(data.creators.first.name, '新しい名前');
      expect(data.creators.first.bio, '自己紹介');
      expect(data.creators.first.types, ['game']);
      await container.read(profileEditViewModelProvider('minato').future);
      expect(sub.read().value?.initialName, '新しい名前');
    });

    test('登録の手順では、ID を確かめて下書きに入れるだけで、発信者は作らない', () async {
      final keep = container.listen(registrationDraftProvider, (_, _) {});
      await container.read(profileEditViewModelProvider(null).future);
      final vm = container.read(profileEditViewModelProvider(null).notifier);
      expect(
        await vm.save(name: '新人', bio: '', types: const [], id: 'Bad ID'),
        ProfileSaveError.idInvalid,
      );
      expect(
        await vm.save(name: '新人', bio: '', types: const [], id: 'new_one'),
        isNull,
      );
      final draft = keep.read();
      expect(draft.profileName, '新人');
      expect(draft.profileId, 'new_one');
      expect(draft.profileDone, isTrue);
      expect(data.creators.map((c) => c.id), ['minato']);
    });

    test('登録の手順で選んだカバーとアイコンは、下書きに残し、開き直すと出す', () async {
      final keep = container.listen(registrationDraftProvider, (_, _) {});
      await container.read(profileEditViewModelProvider(null).future);
      final vm = container.read(profileEditViewModelProvider(null).notifier);
      final avatar = Uint8List.fromList([1]);
      final cover = Uint8List.fromList([2]);
      expect(
        await vm.save(
          name: '新人',
          bio: '',
          types: const [],
          id: 'new_one',
          avatar: avatar,
          cover: cover,
        ),
        isNull,
      );
      expect(keep.read().profileAvatar, avatar);
      expect(keep.read().profileCover, cover);
      // 画像を選び直さずに保存し直しても、前に選んだものを残す。
      expect(
        await vm.save(name: '新人2', bio: '', types: const [], id: 'new_one'),
        isNull,
      );
      expect(keep.read().profileCover, cover);
      final state = await container.read(
        profileEditViewModelProvider(null).future,
      );
      expect(state.initialCover, cover);
      expect(state.initialAvatar, avatar);
    });

    test('取り込んだ名前は、見た目の1文字で100文字に、絵文字の途中で割らずに切る', () {
      final ninetyNine = 'あ' * 99;
      // 100文字目の絵文字は残し、101文字目からは落とす。
      expect(ProfileEditViewModel.clampName('$ninetyNine😀い'), '$ninetyNine😀');
      // 組み合わせの絵文字（家族・肌の色・旗）も、1文字と数え、まるごと残すか落とす。
      expect(
        ProfileEditViewModel.clampName('$ninetyNine👨‍👩‍👧‍👦👍🏽'),
        '$ninetyNine👨‍👩‍👧‍👦',
      );
      expect(ProfileEditViewModel.clampName('🇯🇵' * 120), '🇯🇵' * 100);
      expect(ProfileEditViewModel.clampName('短い名前'), '短い名前');
    });

    test('名前は、見た目の1文字で数えて100文字までなら保存できる', () async {
      container.listen(profileEditViewModelProvider('minato'), (_, _) {});
      await container.read(profileEditViewModelProvider('minato').future);
      final vm = container.read(
        profileEditViewModelProvider('minato').notifier,
      );
      // 合字・肌の色・旗の絵文字100文字（UTF-16 では100を大きく超える）。
      final emojis = '👨‍👩‍👧‍👦👍🏽🇯🇵👩🏽‍❤️‍💋‍👨🏻' * 25;
      expect(await vm.save(name: emojis, bio: '', types: const []), isNull);
      expect(data.creators.first.name, emojis);
      expect(
        await vm.save(name: '$emojis😀', bio: '', types: const []),
        ProfileSaveError.nameInvalid,
      );
    });

    test('取り込み元は、確認済みの SNS だけ', () async {
      data.creators[0] = Creator(
        id: 'minato',
        name: '星野ミナト',
        linkedAccounts: const {
          SnsService.youtube: CreatorAccount(
            service: SnsService.youtube,
            account: 'UC123',
            verified: true,
          ),
          SnsService.instagram: CreatorAccount(
            service: SnsService.instagram,
            account: 'minato_ig',
          ),
        },
      );
      container.listen(profileEditViewModelProvider('minato'), (_, _) {});
      final state = await container.read(
        profileEditViewModelProvider('minato').future,
      );
      expect(state.importSources, [SnsService.youtube]);
      expect(state.creator?.id, 'minato');
      expect(state.initialId, isNull);
    });

    Creator withVerifiedX({bool xOption = false}) => Creator(
      id: 'minato',
      name: '星野ミナト',
      xOption: xOption,
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
    );

    Future<List<SnsService>> sourcesOf(Creator creator) async {
      data.creators[0] = creator;
      container.listen(profileEditViewModelProvider('minato'), (_, _) {});
      final state = await container.read(
        profileEditViewModelProvider('minato').future,
      );
      return state.importSources;
    }

    test('X連携プランに加入していなければ、取り込み元に X を出さない', () async {
      expect(await sourcesOf(withVerifiedX()), [SnsService.youtube]);
    });

    test('X連携プランに加入していれば、取り込み元に X を出す', () async {
      expect(
        await sourcesOf(withVerifiedX(xOption: true)),
        contains(SnsService.x),
      );
    });

    test('登録の途中は、取り込み元に X を出さない', () async {
      data.pendingLinks[SnsService.youtube] = const CreatorAccount(
        service: SnsService.youtube,
        account: 'UC123',
        verified: true,
      );
      data.pendingLinks[SnsService.x] = const CreatorAccount(
        service: SnsService.x,
        account: 'minato_x',
        verified: true,
      );
      container.listen(profileEditViewModelProvider(null), (_, _) {});
      await container.read(pendingAccountLinksProvider.future);
      final state = await container.read(
        profileEditViewModelProvider(null).future,
      );
      expect(state.importSources, [SnsService.youtube]);
    });
  });

  group('アカウント連携', () {
    test('発信者の連携は、連携・解除のたびに読み直す', () async {
      final sub = container.listen(
        accountLinkViewModelProvider('minato'),
        (_, _) {},
      );
      final vm = container.read(
        accountLinkViewModelProvider('minato').notifier,
      );
      await container.read(accountLinkViewModelProvider('minato').future);
      expect(await vm.linkAccount(SnsService.twitch), AccountLinkResult.linked);
      await container.read(accountLinkViewModelProvider('minato').future);
      expect(sub.read().value?[SnsService.twitch]?.account, 'twitch_linked');

      expect(await vm.unlinkAccount(SnsService.twitch), isTrue);
      await container.read(accountLinkViewModelProvider('minato').future);
      expect(sub.read().value?.containsKey(SnsService.twitch), isFalse);
    });

    test('登録の手順では、登録待ちの連携を扱い、取り戻せる発信者が見つかっても読み直す', () async {
      final sub = container.listen(
        accountLinkViewModelProvider(null),
        (_, _) {},
      );
      final vm = container.read(accountLinkViewModelProvider(null).notifier);
      expect(
        await container.read(accountLinkViewModelProvider(null).future),
        {},
      );
      expect(
        await vm.linkAccount(SnsService.youtube),
        AccountLinkResult.linked,
      );
      await container.read(accountLinkViewModelProvider(null).future);
      expect(sub.read().value?.keys, [SnsService.youtube]);
      // 登録待ちの連携は、発信者には付けない。
      expect(data.pendingLinks.keys, [SnsService.youtube]);

      data.linkResult = AccountLinkResult.reclaimable;
      data.reclaimable.add(
        ReclaimableCreator(
          id: 'left_one',
          name: '退会した発信者',
          purgeAt: DateTime(2026, 12, 1),
        ),
      );
      expect(
        await vm.linkAccount(SnsService.twitch),
        AccountLinkResult.reclaimable,
      );
      expect(
        (await container.read(reclaimableCreatorsProvider.future)).single.id,
        'left_one',
      );
    });
  });

  group('プラン', () {
    test('購入のあと、サーバーに加入を書き直させてから、発信者の値を読み直す', () async {
      var readsAtSync = -1;
      data
        ..ownedCreatorId = 'minato'
        ..onSubscriptionSync = () {
          readsAtSync = data.ownedCreatorReads;
          data.creators[0] = const Creator(
            id: 'minato',
            name: '星野ミナト',
            xOption: true,
          );
        };
      container.listen(ownedCreatorProvider, (_, _) {});
      expect(
        (await container.read(ownedCreatorProvider.future))?.xOption,
        false,
      );
      container.listen(planViewModelProvider, (_, _) {});
      await container.read(planViewModelProvider.future);

      final vm = container.read(planViewModelProvider.notifier);
      expect(await vm.purchase(), PlanPurchaseResult.purchased);
      expect(data.subscriptionSyncs, 1);
      expect(
        (await container.read(ownedCreatorProvider.future))?.xOption,
        true,
      );
      // 書き直させたあとに、読み直している。
      expect(data.ownedCreatorReads, greaterThan(readsAtSync));

      // 購入の復元のあとも、書き直させる。
      data.restorable = subscribed();
      expect(await vm.restore(), isTrue);
      expect(data.subscriptionSyncs, 2);
    });

    test('サーバーに書き直させられなくても、購入は済ませ、読み直す', () async {
      data
        ..ownedCreatorId = 'minato'
        ..subscriptionSyncFails = true;
      container.listen(planViewModelProvider, (_, _) {});
      await container.read(planViewModelProvider.future);
      final vm = container.read(planViewModelProvider.notifier);
      expect(await vm.purchase(), PlanPurchaseResult.purchased);
      expect(data.subscriptionSyncs, 1);
      final state = await container.read(planViewModelProvider.future);
      expect(state.subscription.xOption, isTrue);
    });
  });

  group('発信者として登録', () {
    test('2つの手順と同意がそろうと、プランの加入がなくても登録でき、登録すると下書きの内容で発信者を作る', () async {
      data.pendingLinks[SnsService.youtube] = const CreatorAccount(
        service: SnsService.youtube,
        account: 'UCnew',
        verified: true,
      );
      final sub = container.listen(creatorRegisterViewModelProvider, (_, _) {});
      final vm = container.read(creatorRegisterViewModelProvider.notifier);
      expect(sub.read().canRegister, isFalse);
      await container.read(pendingAccountLinksProvider.future);
      expect(sub.read().linkedServices, [SnsService.youtube]);
      expect(sub.read().profileDone, isFalse);

      container
          .read(registrationDraftProvider.notifier)
          .setProfile(id: 'new_one', name: '新人', bio: '', types: ['game']);
      vm.setAgreed(true);
      expect(sub.read().profileDone, isTrue);
      expect(sub.read().agreed, isTrue);
      expect(sub.read().canRegister, isTrue);
      expect(await vm.hasLoginMethod(), isFalse);

      expect(await vm.register(), RegisterResult.registered);
      expect(data.ownedCreatorId, 'new_one');
      expect(data.creators.last.types, ['game']);
      expect(data.creators.last.linkedAccounts.keys, [SnsService.youtube]);
    });

    test('登録の手順で選んだアイコンとカバーを、登録に渡す', () async {
      final avatar = Uint8List.fromList([1]);
      final cover = Uint8List.fromList([2]);
      container.listen(creatorRegisterViewModelProvider, (_, _) {});
      container
          .read(registrationDraftProvider.notifier)
          .setProfile(
            id: 'new_one',
            name: '新人',
            bio: '',
            types: const [],
            avatar: avatar,
            cover: cover,
          );
      final vm = container.read(creatorRegisterViewModelProvider.notifier);
      expect(await vm.register(), RegisterResult.registered);
      expect(data.registeredAvatar, avatar);
      expect(data.registeredCover, cover);
      expect(data.creators.last.coverUrl, 'memory://cover');
    });

    test('登録のあとに画像を上げられなければ、登録は済ませ、一部を保存できなかったと返す', () async {
      data.registerUploadFails = true;
      container.listen(creatorRegisterViewModelProvider, (_, _) {});
      container
          .read(registrationDraftProvider.notifier)
          .setProfile(
            id: 'new_one',
            name: '新人',
            bio: '',
            types: const [],
            cover: Uint8List.fromList([2]),
          );
      final vm = container.read(creatorRegisterViewModelProvider.notifier);
      final result = await vm.register();
      expect(result, RegisterResult.registeredPartially);
      expect(result.isRegistered, isTrue);
      expect(data.ownedCreatorId, 'new_one');
      expect(data.creators.last.coverUrl, isNull);
    });
  });

  group('サインインの失敗からのやり直し（設計書 4.2）', () {
    /// サインインから失敗した画面が、[retry] で、サインインをやり直して読めるようになる。
    Future<void> expectRecovers<T>(
      ProviderListenable<AsyncValue<T>> provider,
      void Function() retry,
    ) async {
      data.failReads = true;
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      expect(sub.read().hasError, isTrue);

      data.failReads = false;
      retry();
      await pumpEventQueue();
      expect(sub.read().hasValue, isTrue);
    }

    test(
      '発信者メニュー',
      () => expectRecovers(
        creatorMenuViewModelProvider('minato'),
        () => container
            .read(creatorMenuViewModelProvider('minato').notifier)
            .retry(),
      ),
    );

    test(
      '表示する内容',
      () => expectRecovers(
        displayContentsViewModelProvider('minato'),
        () => container
            .read(displayContentsViewModelProvider('minato').notifier)
            .retry(),
      ),
    );

    test(
      'カレンダー予定（一覧）',
      () => expectRecovers(
        eventManageViewModelProvider('minato'),
        () => container
            .read(eventManageViewModelProvider('minato').notifier)
            .retry(),
      ),
    );

    test(
      'アカウント連携',
      () => expectRecovers(
        accountLinkViewModelProvider('minato'),
        () => container
            .read(accountLinkViewModelProvider('minato').notifier)
            .retry(),
      ),
    );

    test(
      'プロフィールの編集',
      () => expectRecovers(
        profileEditViewModelProvider('minato'),
        () => container
            .read(profileEditViewModelProvider('minato').notifier)
            .retry(),
      ),
    );

    test(
      'プラン',
      () => expectRecovers(
        planViewModelProvider,
        () => container.read(planViewModelProvider.notifier).retry(),
      ),
    );
  });

  group('サインインを待つ読み込み', () {
    const key = EventCandidatesKey('minato', ['https://example.com/a']);

    test('イベントの候補は、サインインが終わるまで読まない', () async {
      final gate = data.signInGate = Completer<void>();
      data.failReads = true;
      final sub = container.listen(
        eventCandidatesViewModelProvider(key),
        (_, _) {},
      );
      addTearDown(sub.close);
      await pumpEventQueue();
      // 読みに行っていれば、失敗している。
      expect(sub.read().isLoading, isTrue);
      expect(sub.read().hasError, isFalse);

      data.failReads = false;
      gate.complete();
      await pumpEventQueue();
      expect(sub.read().hasValue, isTrue);
    });

    test('イベントの候補と登録済みの公演は、ユーザーが切り替わると読み直す', () async {
      final urls = container.listen(
        eventCandidatesViewModelProvider(key),
        (_, _) {},
      );
      addTearDown(urls.close);
      final performances = container.listen(
        registeredPerformancesProvider('minato'),
        (_, _) {},
      );
      addTearDown(performances.close);
      await pumpEventQueue();
      expect(urls.read().requireValue, isEmpty);
      expect(performances.read().requireValue, isEmpty);

      data.events['e1'] = const Event(
        id: 'e1',
        creatorId: 'minato',
        title: '周年ライブ',
        links: [EventLink(url: 'https://example.com/a')],
        performances: [],
      );
      data.schedules.add(
        sampleSchedule('s1', '周年ライブ', DateTime(2026, 12, 1), eventId: 'e1'),
      );
      data.switchSessionUser('user-b');
      await pumpEventQueue();
      expect(urls.read().requireValue, {'https://example.com/a'});
      expect(performances.read().requireValue, isNotEmpty);
    });
  });
}
