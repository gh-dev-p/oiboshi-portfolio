import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/ui/creator_admin/widgets/plan_screen.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/core/ui/skeleton.dart';
import 'package:oiboshi/ui/creator_admin/widgets/profile_edit_screen.dart';
import 'package:oiboshi/domain/models/sns_profile.dart';
import 'package:oiboshi/domain/models/creator_settings.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/creator_admin/widgets/account_link_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_register_screen.dart';

import 'package:oiboshi/ui/creator_admin/widgets/creator_menu_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

/// 発信者として登録の、規約への同意の文。
const consentText = '利用規約・プライバシーポリシー・発信者向けの利用規約に同意する';

/// 規約への同意のチェックボックスを押す。文の名前はリンクなので、文の左のチェックボックスを押す。
Future<void> agreeToTerms(WidgetTester tester) async {
  await tester.dragUntilVisible(
    find.text(consentText),
    find.byType(ListView),
    const Offset(0, -200),
  );
  final text = tester.getRect(find.text(consentText));
  await tester.tapAt(Offset(text.left - 21, text.center.dy));
  await tester.pumpAndSettle();
}

void main() {
  setUpScreenTests();

  testWidgets('本人の確認を閉じたら、連携を解除しない。この端末で使えないログイン方法だけなら、そう出す', (tester) async {
    data.loginMethods.add(appleLogin);
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    await tester.tap(find.text('確認済み').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('解除する'));
    await tester.pumpAndSettle();
    // テストは Android 扱いなので、Apple は使えない。
    expect(find.text('本人の確認'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsNothing);
    expect(
      find.text('この端末では、結び付けたログイン方法を使えません。iPhone で操作してください。'),
      findsOneWidget,
    );
    await tester.tapAt(const Offset(200, 50));
    await tester.pumpAndSettle();
    expect(find.text('本人の確認'), findsNothing);
    expect(find.text('確認済み'), findsNWidgets(2));
    expect(data.reauthCount, 0);
    await unmount(tester);
  });

  testWidgets('アカウント連携は、未連携・未確認・確認済みを分けて出す', (tester) async {
    // SNS ごとの面が縦に長いので、全部の行が作られる高さにする。
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    expect(find.text('@UC123'), findsOneWidget);
    expect(find.text('確認済み'), findsOneWidget);
    // この版で出さない SNS（v1.0.0 の Instagram・ツイキャス）は「準備中」にし、連携済みのアカウントも出さない（機能仕様書 4.6.2）。
    final ig = instagramOffered ? 1 : 0;
    final tc = twitcastingOffered ? 1 : 0;
    expect(
      find.text('@minato_ig'),
      instagramOffered ? findsOneWidget : findsNothing,
    );
    // Instagram（未確認）、X・ツイキャス・Twitch（未連携）のうち、出すもの。
    expect(find.text('連携する'), findsNWidgets(2 + ig + tc));
    await tester.scrollUntilVisible(
      find.text('ニコニコ'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('ニコニコ'), findsOneWidget);
    // 未連携の X・ツイキャス・Twitch と、準備中の TikTok・ニコニコ・出さない SNS。
    expect(
      find.text('未連携'),
      findsNWidgets((2 + tc) + (2 + (1 - ig) + (1 - tc))),
    );
    expect(find.text('準備中'), findsNWidgets(2 + (1 - ig) + (1 - tc)));
    // 出さない SNS の行を押しても、連携も DM の手順も始まらない。
    if (!instagramOffered) {
      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();
      expect(find.text('Instagram を DM で確認'), findsNothing);
      expect(find.text('Instagramを連携しました'), findsNothing);
    }
    if (!twitcastingOffered) {
      await tester.tap(find.text('ツイキャス'));
      await tester.pumpAndSettle();
      expect(find.text('ツイキャスを連携しました'), findsNothing);
    }
    await unmount(tester);
  });

  testWidgets('アカウント連携で、連携して、解除できる', (tester) async {
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
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    // 並びは YouTube（確認済み）・X・Instagram・ツイキャス・Twitch。ツイキャスを連携する。
    // ツイキャスを出さない版（v1.0.0）は、Twitch。どちらも、X と（出すなら）Instagram の次の「連携する」。
    final (target, name) = twitcastingOffered
        ? ('twitcasting', 'ツイキャス')
        : ('twitch', 'Twitch');
    await tester.tap(find.text('連携する').at(instagramOffered ? 2 : 1));
    await tester.pumpAndSettle();
    expect(find.text('$nameを連携しました'), findsOneWidget);
    expect(find.text('@${target}_linked'), findsOneWidget);
    expect(find.text('確認済み'), findsNWidgets(2));

    await tester.tap(find.text('@${target}_linked'));
    await tester.pumpAndSettle();
    expect(find.text('$nameの連携を解除しますか？'), findsOneWidget);
    expect(find.textContaining('90日のうちに、同じアカウントを連携し直すと'), findsOneWidget);
    await tester.tap(find.text('解除する'));
    await tester.pumpAndSettle();
    expect(find.text('@${target}_linked'), findsNothing);
    expect(find.text('確認済み'), findsOneWidget);

    // Instagram（未確認）も、OAuth で連携して確認済みにする。「連携する」は X・Instagram・ツイキャス・Twitch の順。
    if (instagramOffered) {
      await tester.tap(find.text('連携する').at(1));
      await tester.pumpAndSettle();
      expect(find.text('Instagramを連携しました'), findsOneWidget);
      expect(find.text('@instagram_linked'), findsOneWidget);
      expect(find.text('確認済み'), findsNWidgets(2));
    }
    await unmount(tester);
  });

  testWidgets('アカウント連携で、ほかの発信者のアカウントは断られる', (tester) async {
    data.linkResult = AccountLinkResult.duplicate;
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
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    await tester.tap(find.text('連携する').first);
    await tester.pumpAndSettle();
    expect(find.text('このアカウントは、ほかの発信者で連携されています'), findsOneWidget);
    expect(find.text('確認済み'), findsOneWidget);

    // Instagram も、ほかの発信者で確認済みなら断られ、未確認のまま。
    if (instagramOffered) {
      await tester.tap(find.text('連携する').at(2));
      await tester.pumpAndSettle();
      expect(find.text('このアカウントは、ほかの発信者で連携されています'), findsOneWidget);
      expect(find.text('@minato_ig'), findsOneWidget);
      expect(find.text('確認済み'), findsOneWidget);
    }
    await unmount(tester);
  });

  testWidgets('発信者として登録の手順1から連携すると、手順1が済む', (tester) async {
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    await tester.tap(find.text('SNSアカウントを連携'));
    await tester.pumpAndSettle();
    // 何も連携していないので、YouTube の「連携する」が先頭。
    await tester.tap(find.text('連携する').first);
    await tester.pumpAndSettle();
    expect(find.text('YouTubeを連携しました'), findsOneWidget);
    expect(find.text('@youtube_linked'), findsOneWidget);
    expect(data.pendingLinks.containsKey(SnsService.youtube), isTrue);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('YouTube を連携済み'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('手順1で、オーナーが退会した発信者のアカウントを連携すると、取り戻しの案内に戻る', (tester) async {
    data.linkResult = AccountLinkResult.reclaimable;
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    await tester.tap(find.text('SNSアカウントを連携'));
    await tester.pumpAndSettle();
    data.reclaimable.add(
      ReclaimableCreator(
        id: 'left_one',
        name: '退会した発信者',
        purgeAt: DateTime(2026, 12, 1),
      ),
    );
    await tester.tap(find.text('連携する').first);
    await tester.pumpAndSettle();
    expect(find.text('オーナーが退会した発信者のアカウントです。登録の画面から、取り戻せます'), findsOneWidget);
    expect(find.text('発信者を取り戻せます'), findsOneWidget);
    expect(find.textContaining('2026年12月1日までに取り戻すと'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('取り戻しの案内は、基本プランの発信者にだけ、X の連携の引き継ぎを出す', (tester) async {
    data.reclaimable.add(
      ReclaimableCreator(
        id: 'left_one',
        name: '退会した発信者',
        purgeAt: DateTime(2026, 12, 1),
      ),
    );
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    expect(find.textContaining('「購入を復元」で引き継げます'), findsOneWidget);
    await unmount(tester);

    data.reclaimable[0] = ReclaimableCreator(
      id: 'left_one',
      name: '退会した発信者',
      purgeAt: DateTime(2026, 12, 1),
      plan: CreatorPlan.complimentary,
    );
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    expect(find.textContaining('「購入を復元」で引き継げます'), findsNothing);
    expect(find.textContaining('そのまま戻ります。'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('取り戻しは、アカウント作成のあとだけ。匿名なら知らせて、ログイン方法は結び付けない', (tester) async {
    data.reclaimable.add(
      ReclaimableCreator(
        id: 'left_one',
        name: '退会した発信者',
        purgeAt: DateTime(2026, 12, 1),
      ),
    );
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    await tester.tap(find.text('取り戻す'));
    await tester.pumpAndSettle();
    expect(find.text('先にアカウントを作成してください'), findsOneWidget);
    expect(find.text('アカウント作成／ログイン'), findsNothing);
    expect(data.ownedCreatorId, isNull);
    expect(data.loginMethods, isEmpty);
    await unmount(tester);

    data.loginMethods.add(googleLogin);
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    await tester.tap(find.text('取り戻す'));
    await tester.pumpAndSettle();
    expect(data.ownedCreatorId, 'left_one');
    await unmount(tester);
  });

  testWidgets('プロフィールの編集で、確認済みの SNS から下書きを取り込める', (tester) async {
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
    data.profileDraft = (s) => s == SnsService.youtube
        ? const SnsProfileDraft(
            service: SnsService.youtube,
            name: 'ミナトch',
            bio: '歌ってます',
          )
        : null;
    await pumpScreen(
      tester,
      data,
      const ProfileEditScreen(creatorId: 'minato'),
    );
    // 未確認の Instagram は、取り込み元に出さない。
    expect(find.text('Instagram'), findsNothing);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('YouTubeから、下書きを入れました'), findsOneWidget);
    expect(find.text('ミナトch'), findsOneWidget);
    expect(find.text('歌ってます'), findsOneWidget);
    expect(find.text('下書き・YouTubeから'), findsNWidgets(2));
    // 保存するまでは、反映しない。
    expect(data.creators.first.name, '星野ミナト');
    await unmount(tester);
  });

  testWidgets('取り込みの回数の上限を超えたら、時間をおくよう知らせ、下書きは入れない', (tester) async {
    data.ownedCreatorId = 'minato';
    data.profileImportLimited = true;
    data.profileDraft = (s) =>
        const SnsProfileDraft(service: SnsService.youtube, name: 'ミナトch');
    await pumpScreen(
      tester,
      data,
      const ProfileEditScreen(creatorId: 'minato'),
    );
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('YouTubeからの取り込みは、しばらく時間をおいてお試しください'), findsOneWidget);
    expect(find.text('ミナトch'), findsNothing);
    await unmount(tester);
  });

  testWidgets('取り込んだ名前は、見た目の1文字で100文字に収め、絵文字を割らずに切る', (tester) async {
    data.ownedCreatorId = 'minato';
    // 100文字目の絵文字は残し、101文字目の家族の絵文字（合字）は、まるごと落とす。
    final kept = '${'あ' * 98}🇯🇵👍🏽';
    data.profileDraft = (s) =>
        SnsProfileDraft(service: SnsService.youtube, name: '$kept👨‍👩‍👧‍👦');
    await pumpScreen(
      tester,
      data,
      const ProfileEditScreen(creatorId: 'minato'),
    );
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.controller!.text, kept);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    // UTF-16 では100を超えるが、見た目の1文字では100文字なので、保存できる。
    expect(data.creators.first.name, kept);
    await unmount(tester);
  });

  testWidgets('登録の手順で選んだカバーを残し、登録したあとに保存する。上げられなければ知らせる', (tester) async {
    // カバー（横3：縦1）が画面の幅で伸びるので、スマホの大きさで確かめる。
    usePhoneScreen(tester);
    final cover = Uint8List.fromList(_transparentPng);
    final picker = FakeImagePickerService(picked: cover);
    data
      ..pendingLinks[SnsService.youtube] = const CreatorAccount(
        service: SnsService.youtube,
        account: 'UCnew',
        verified: true,
      )
      ..loginMethods.add(googleLogin)
      ..registerUploadFails = true;
    // 登録すると前の画面に戻り、スナックバーを出すので、前の画面から開く。
    await pumpOpener(
      tester,
      data,
      (context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CreatorRegisterScreen()),
      ),
      picker: picker,
    );

    Finder coverImage() =>
        find.byWidgetPredicate((w) => w is Image && w.image is MemoryImage);
    await tester.tap(find.text('プロフィールを入力'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('カバーを変える'));
    await tester.pumpAndSettle();
    expect(coverImage(), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '新しい発信者');
    await tester.enterText(find.byType(TextField).last, 'new_one');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 開き直しても、選んだカバーが残っている。
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.tap(find.text('新しい発信者（@new_one）として入力済み'));
    await tester.pumpAndSettle();
    expect(coverImage(), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(find.text('新しい発信者（@new_one）として入力済み'), findsOneWidget);

    await agreeToTerms(tester);
    await tester.dragUntilVisible(
      find.text('発信者として登録する'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('発信者として登録する'));
    await tester.pumpAndSettle();
    expect(data.registeredCover, cover);
    expect(data.ownedCreatorId, 'new_one');
    expect(
      find.text('発信者として登録しました。プロフィールの一部を保存できなかったので、プロフィールの編集で直してください'),
      findsOneWidget,
    );
    expect(find.text('開く'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('プロフィールの編集で、タイプを3つまで選んで保存できる', (tester) async {
    data.creators[0] = sampleCreator().copyWith(types: ['game']);
    data.ownedCreatorId = 'minato';
    await pumpScreen(
      tester,
      data,
      const ProfileEditScreen(creatorId: 'minato'),
    );
    await tester.dragUntilVisible(
      find.text('ASMR'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('歌'));
    await tester.tap(find.text('ASMR'));
    await tester.pumpAndSettle();
    // 3つ選ぶと、ほかは押せない。
    await tester.tap(find.text('雑談'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(data.creators.first.types, ['game', 'singing', 'asmr']);
    await unmount(tester);
  });

  testWidgets('登録の同意は、利用規約・プライバシーポリシー・発信者向けの利用規約の3つをまとめて取り、名前をリンクにする', (
    tester,
  ) async {
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    await tester.dragUntilVisible(
      find.text(consentText),
      find.byType(ListView),
      const Offset(0, -200),
    );
    final links = <String>[];
    tester.widget<Text>(find.text(consentText)).textSpan!.visitChildren((span) {
      if (span is TextSpan && span.recognizer != null) links.add(span.text!);
      return true;
    });
    expect(links, ['利用規約', 'プライバシーポリシー', '発信者向けの利用規約']);
    await unmount(tester);
  });

  testWidgets('アカウントを作ったユーザーは、2つの手順と同意のあと、発信者として登録できる', (tester) async {
    // カバー（横3：縦1）が画面の幅で伸びるので、スマホの大きさで確かめる。
    usePhoneScreen(tester);
    data
      ..loginMethods.add(googleLogin)
      ..pendingLinks[SnsService.youtube] = const CreatorAccount(
        service: SnsService.youtube,
        account: 'UCnew',
        verified: true,
      );
    await pumpScreen(tester, data, const CreatorRegisterScreen());
    // 文言（2026-11-10 本人）。プロフィールの補足と、ボタンの下の注記は出さない。
    expect(find.text('あなたの配信・投稿・イベントを\nファンに届けます'), findsOneWidget);
    expect(find.text('FOR CREATORS'), findsOneWidget);
    // 見出しの右の緑の星は、飾りなので読み上げない。
    final star = find.image(
      const AssetImage(CreatorRegisterScreen.greenStarCharacter),
    );
    expect(star, findsOneWidget);
    expect(
      find.ancestor(of: star, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    expect(
      find.text('連携したいSNSアカウントにサインインしてください。\n投稿やフォロワー数、リンクなどがアプリに表示されます。'),
      findsOneWidget,
    );
    expect(find.text('YouTube を連携済み'), findsOneWidget);
    expect(find.text('連携したSNSから、下書きを入れられます'), findsNothing);
    expect(find.text('2つの手順と、規約への同意が済むと、押せるようになります。'), findsNothing);

    await tester.tap(find.text('プロフィールを入力'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '新しい発信者');
    await tester.enterText(find.byType(TextField).last, 'Bad ID');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('IDは、英小文字・数字・_・- の1〜40文字で入力してください'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'new_one');
    // タイプは任意。選ぶと、登録したときに保存する。
    await tester.dragUntilVisible(
      find.text('ゲーム'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('ゲーム'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('新しい発信者（@new_one）として入力済み'), findsOneWidget);
    // 前のスナックバーが、下のボタンに重ならないように消す。
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();

    // 2つの手順が済んでも、規約に同意するまでは、登録のボタンを押せない（プランの加入は要らない）。
    await tester.dragUntilVisible(
      find.text('発信者として登録する'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(
      tester
          .widget<PrimaryButton>(
            find.widgetWithText(PrimaryButton, '発信者として登録する'),
          )
          .onPressed,
      isNull,
    );
    await agreeToTerms(tester);

    await tester.dragUntilVisible(
      find.text('発信者として登録する'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('発信者として登録する'));
    await tester.pumpAndSettle();
    // 登録の流れの中では、ログイン方法を結び付けない。
    expect(find.text('アカウント作成／ログイン'), findsNothing);
    // 登録すると、前の画面（設定）に戻る。テストでは下に画面がないので、データで確かめる。
    expect(data.ownedCreatorId, 'new_one');
    expect(data.creators.last.types, ['game']);
    expect(data.loginMethods.single.provider, LoginProvider.google);
    expect(
      data.creators.last.linkedAccounts.containsKey(SnsService.youtube),
      isTrue,
    );
    await unmount(tester);
  });

  testWidgets('永年無料のプランは、X を選べ、プランの画面に料金がかからないと出す', (tester) async {
    data.creators[0] = Creator(
      id: 'minato',
      name: '星野ミナト',
      plan: CreatorPlan.complimentary,
      // 永年無料は X を含むので、サーバーが x_option を真で返す。
      xOption: true,
      linkedAccounts: const {
        SnsService.x: CreatorAccount(
          service: SnsService.x,
          account: 'minato_x',
          verified: true,
        ),
      },
    );
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    expect(find.text('X連携プラン（月290円）に加入すると使えます'), findsNothing);
    await unmount(tester);

    await pumpScreen(
      tester,
      data,
      const PlanScreen(plan: CreatorPlan.complimentary),
    );
    expect(find.text('永年無料'), findsOneWidget);
    expect(find.text('料金はかかりません（X の連携を含む）'), findsOneWidget);
    expect(find.text('解約する'), findsNothing);
    expect(find.text('加入する'), findsNothing);
    await unmount(tester);
  });

  testWidgets('表示する内容は、X連携プランに加入しているときだけ X を選べる', (tester) async {
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    await tester.scrollUntilVisible(
      find.text('X'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('X連携プラン（月290円）に加入すると使えます'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('配信・動画'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('ニコニコ'), findsOneWidget);
    expect(find.text('配信・ショート動画'), findsOneWidget);
    await unmount(tester);

    data.creators[0] = Creator(
      id: 'minato',
      name: '星野ミナト',
      linkedAccounts: sampleCreator().linkedAccounts,
      xOption: true,
    );
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    await tester.scrollUntilVisible(
      find.text('X'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('X連携プラン（月290円）に加入すると使えます'), findsNothing);
    await unmount(tester);
  });

  testWidgets('表示する内容の X の注記は、ストアの月額を出す。読めないときは、アプリに持つ月額', (tester) async {
    Future<void> expectNote(String text) async {
      await pumpScreen(
        tester,
        data,
        const AccountLinkScreen(creatorId: 'minato'),
      );
      await tester.scrollUntilVisible(
        find.text('X'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(text), findsOneWidget);
      await unmount(tester);
    }

    // 日本円は「{金額}円」。
    data.xOptionPrice = const PlanPrice(
      amount: 300,
      currencyCode: 'JPY',
      formatted: '¥300',
    );
    await expectNote('X連携プラン（月300円）に加入すると使えます');
    // ほかの通貨は、ストアの書き方のまま。
    data.xOptionPrice = const PlanPrice(
      amount: 1.99,
      currencyCode: 'USD',
      formatted: r'$1.99',
    );
    await expectNote(r'X連携プラン（月$1.99）に加入すると使えます');
    // 読めないとき・課金を使えない端末では、アプリに持つ月額。
    data.offerFails = true;
    await expectNote('X連携プラン（月290円）に加入すると使えます');
    data.offerFails = false;
    data.billingAvailable = false;
    await expectNote('X連携プラン（月290円）に加入すると使えます');
  });

  testWidgets('アカウント連携は、読み込み中は行をスケルトンにし、押せない', (tester) async {
    await tester.pumpWidget(
      await testApp(data, const AccountLinkScreen(creatorId: 'minato')),
    );
    // 最初のフレーム（まだ読めていない）。
    expect(find.byType(SkeletonIconRow), findsNWidgets(5));
    expect(find.text('連携する'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonIconRow), findsNothing);
    expect(find.text('確認済み'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('停止中の発信者の発信者メニューに、停止中の注意とお問い合わせを出す', (tester) async {
    data
      ..ownedCreatorId = 'minato'
      ..creators[0] = sampleCreator().copyWith().withSuspended();
    await pumpScreen(
      tester,
      data,
      const CreatorMenuScreen(creatorId: 'minato'),
    );
    expect(find.text('この発信者は、運営が表示を止めています。くわしくは、お問い合わせください。'), findsOneWidget);
    expect(find.text('お問い合わせ'), findsOneWidget);
    await unmount(tester);

    data.creators[0] = sampleCreator();
    await pumpScreen(
      tester,
      data,
      const CreatorMenuScreen(creatorId: 'minato'),
    );
    expect(find.text('お問い合わせ'), findsNothing);
    await unmount(tester);
  });

  testWidgets('表示する内容に、オフにすると取得済みの投稿もすぐ見えなくなる注記を出す', (tester) async {
    await pumpScreen(
      tester,
      data,
      const AccountLinkScreen(creatorId: 'minato'),
    );
    expect(find.text('オフにすると、取得済みの投稿も、すぐにファンに見えなくなります。'), findsOneWidget);
    await unmount(tester);
  });
}

/// 1×1 の透明な PNG（カバーの画像の代わり）。
const _transparentPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

extension on Creator {
  /// 停止中にした発信者（運営が SQL で入れる。機能仕様書 4.6.7）。
  Creator withSuspended() => Creator(
    id: id,
    name: name,
    bio: bio,
    linkedAccounts: linkedAccounts,
    followerCounts: followerCounts,
    plan: plan,
    suspended: true,
  );
}
