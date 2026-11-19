import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/ui/sns_style.dart';
import 'package:oiboshi/ui/core/ui/skeleton.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_menu_screen.dart';
import 'package:oiboshi/ui/creator_admin/widgets/creator_register_screen.dart';
import 'package:oiboshi/ui/home/widgets/home_tabs.dart';
import 'package:oiboshi/ui/settings/widgets/admin_login_form.dart';
import 'package:oiboshi/ui/settings/widgets/login_methods_screen.dart';
import 'package:oiboshi/domain/models/login_method.dart';
import 'package:oiboshi/domain/models/plan_billing.dart';
import 'package:oiboshi/domain/models/user_settings.dart';
import 'package:oiboshi/ui/settings/widgets/hidden_creators_screen.dart';
import 'package:oiboshi/ui/settings/widgets/login_provider_icon.dart';
import 'package:oiboshi/ui/settings/widgets/register_creator_card.dart';
import 'package:oiboshi/ui/settings/widgets/settings_screen.dart';
import 'package:oiboshi/ui/settings/view_models/settings_providers.dart';
import 'package:oiboshi/ui/settings/widgets/withdraw_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  testWidgets('設定の「言語」で English を選ぶと、すぐ英語になり、端末内に保存する', (tester) async {
    data
      ..onboardingDone = true
      ..appLanguage = AppLanguage.ja;
    await pumpScreen(tester, data, const SettingsScreen(), locale: null);
    expect(find.text('設定'), findsOneWidget);
    await tester.tap(find.text('言語'));
    await tester.pumpAndSettle();
    expect(find.text('端末の設定に従う'), findsWidgets);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(data.appLanguage, AppLanguage.en);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('設定から退会すると、初回起動に戻る', (tester) async {
    data.onboardingDone = true;
    await pumpScreen(tester, data, const SettingsScreen());
    expect(find.text('発信者として登録する'), findsOneWidget);
    // 匿名なので、「アカウント作成／ログイン」を出し、「ログイン方法」「ログアウト」は出さない。
    expect(find.text('アカウント作成／ログイン'), findsOneWidget);
    expect(find.text('ログイン方法'), findsNothing);
    expect(find.text('ログアウト'), findsNothing);
    await tester.dragUntilVisible(
      find.text('退会'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('退会'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('退会する'));
    await tester.pumpAndSettle();
    expect(data.onboardingDone, isFalse);
    await unmount(tester);
  });

  Future<void> openAccountEntryAndTap(
    WidgetTester tester,
    String button,
  ) async {
    await tester.tap(find.text('アカウント作成／ログイン'));
    await tester.pumpAndSettle();
    // 説明は置かない（2026-11-10 本人）。
    expect(find.text('初めてなら新しく作り、使ったことがあればログインします。'), findsNothing);
    // テストは Android 扱いなので、Apple は出ない（iOS だけ）。
    expect(find.text('Appleで続ける'), findsNothing);
    await tester.tap(find.text(button));
    await tester.pumpAndSettle();
  }

  testWidgets('アカウント作成／ログインのボタンは、枠・高さ・角の丸み・文字の大きさと太さをそろえる', (tester) async {
    data.onboardingDone = true;
    await pumpScreen(tester, data, const SettingsScreen());
    await tester.tap(find.text('アカウント作成／ログイン'));
    await tester.pumpAndSettle();
    final buttons = tester
        .widgetList<OutlinedButton>(
          find.descendant(
            of: find.byType(LoginProviderButton),
            matching: find.byType(OutlinedButton),
          ),
        )
        .toList();
    // テストは Android 扱いなので、Apple は出ない（Google・X・Twitch）。
    expect(buttons, hasLength(3));
    final sides = buttons
        .map((b) => b.style!.side!.resolve({})!)
        .map((s) => (s.color, s.width))
        .toSet();
    expect(sides, hasLength(1));
    final heights = tester
        .widgetList<LoginProviderButton>(find.byType(LoginProviderButton))
        .map((b) => tester.getSize(find.byWidget(b)).height)
        .toSet();
    expect(heights, {LoginProviderButton.height});
    final labels = ['Google で続行', 'Xで続ける', 'Twitchで続ける']
        .map((t) => tester.widget<Text>(find.text(t)).style!)
        .map((s) => (s.fontSize, s.fontWeight))
        .toSet();
    expect(labels, {
      (LoginProviderButton.fontSize, LoginProviderButton.fontWeight),
    });
    await unmount(tester);
  });

  testWidgets('アカウント作成の前は、発信者として登録するのカードをグレーにして押せない', (tester) async {
    data.onboardingDone = true;
    await pumpScreen(tester, data, const SettingsScreen());
    expect(find.text('先にアカウントを作成してください'), findsOneWidget);
    // 説明文は出さず、タイトルの右に青い星のキャラクターを薄く出す（飾りなので読み上げない）。
    expect(find.text('あなたの配信・投稿・予定を、追星でファンに届けます。'), findsNothing);
    final star = find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName ==
              RegisterCreatorCard.blueStarCharacter,
    );
    expect(star, findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: star, matching: find.byType(Opacity)),
          )
          .opacity,
      0.4,
    );
    expect(
      find.ancestor(of: star, matching: find.byType(ExcludeSemantics)),
      findsWidgets,
    );
    await tester.tap(find.text('発信者として登録する'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorRegisterScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('アカウント作成のあとは、ログイン方法とログアウトを出し、カードから登録へ進める', (tester) async {
    data
      ..onboardingDone = true
      ..loginMethods.add(googleLogin);
    await pumpScreen(tester, data, const SettingsScreen());
    expect(find.text('アカウント作成／ログイン'), findsNothing);
    expect(find.text('ログイン方法'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('ログアウト'), findsOneWidget);
    expect(find.text('先にアカウントを作成してください'), findsNothing);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.image(
                const AssetImage(RegisterCreatorCard.blueStarCharacter),
              ),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      1,
    );
    await tester.tap(find.text('発信者として登録する'));
    await tester.pumpAndSettle();
    expect(find.byType(CreatorRegisterScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('アカウント作成／ログインで、初めてのアカウントなら、いまのユーザーに結び付けてアカウントを作る', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..follows.add(sampleFollow());
    await pumpScreen(tester, data, const SettingsScreen());
    await openAccountEntryAndTap(tester, 'Twitchで続ける');
    expect(find.text('アカウントを作成しました'), findsOneWidget);
    // ユーザー ID とフォローはそのまま。ログインに切り替えない。
    expect(data.userId, 'user-a');
    expect(data.follows.single.creatorId, 'minato');
    expect(data.signInProviders, isEmpty);
    expect(data.mergeTokens, isEmpty);
    // 設定は、ログイン方法とログアウトに変わり、カードを押せるようになる。
    expect(find.text('ログイン方法'), findsOneWidget);
    expect(find.text('Twitch'), findsOneWidget);
    expect(find.text('ログアウト'), findsOneWidget);
    expect(find.text('先にアカウントを作成してください'), findsNothing);
    await unmount(tester);
  });

  testWidgets('アカウント作成／ログインで、使ったことのあるアカウントなら、そのユーザーに入り、フォローを足し合わせる', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..creators.add(hiyori())
      ..follows.addAll([sampleFollow('minato'), sampleFollow('hiyori')])
      ..loginResult = LoginResult.alreadyUsed
      ..signInResult = LoginResult.done
      // ログイン先は、minato をフォローし、hiyori を表示しない。
      ..signInFollows.add(sampleFollow('minato'))
      ..signInHiddenCreatorIds.add('hiyori');
    await pumpScreen(tester, data, const SettingsScreen());
    await openAccountEntryAndTap(tester, 'Xで続ける');
    expect(find.text('ログインしました'), findsOneWidget);
    expect(data.userId, 'user-x');
    expect(data.signInProviders, [LoginProvider.x]);
    // 券を受け取ってからログインし、ログイン先で移す。
    expect(data.mergeTokens, ['merge-1']);
    expect(data.finishedMergeTokens, ['merge-1']);
    // 重なり（minato）は1つ。ログイン先が表示しない発信者（hiyori）は移さない。
    expect(data.follows.map((f) => f.creatorId), ['minato']);
    expect(data.hiddenCreatorIds, ['hiyori']);
    expect(find.text('ログアウト'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('足し合わせの券を受け取れなければ、ログインせずに知らせ、シートを開いたままにする', (tester) async {
    data
      ..onboardingDone = true
      ..loginResult = LoginResult.alreadyUsed
      ..signInResult = LoginResult.done
      ..startMergeFails = true;
    await pumpScreen(tester, data, const SettingsScreen());
    await openAccountEntryAndTap(tester, 'Twitchで続ける');
    expect(find.text('ログインできませんでした。もう一度お試しください'), findsOneWidget);
    expect(find.text('Twitchで続ける'), findsOneWidget);
    expect(data.signInProviders, isEmpty);
    expect(data.userId, 'user-a');
    await unmount(tester);
  });

  testWidgets('使ったことのあるアカウントで、ログインに失敗したら、知らせてシートを開いたままにする', (tester) async {
    data
      ..onboardingDone = true
      ..loginResult = LoginResult.alreadyUsed
      ..signInResult = LoginResult.failed;
    await pumpScreen(tester, data, const SettingsScreen());
    await openAccountEntryAndTap(tester, 'Twitchで続ける');
    expect(find.text('ログインできませんでした。もう一度お試しください'), findsOneWidget);
    expect(find.text('Twitchで続ける'), findsOneWidget);
    expect(data.userId, 'user-a');
    expect(data.finishedMergeTokens, isEmpty);
    await unmount(tester);
  });

  testWidgets('アプリ運営用ログインで、運営が作ったアカウントに入り、フォローを足し合わせる。5回違ったら入れない', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..follows.add(sampleFollow('minato'))
      ..passwordAccounts['review@example.com'] = 'right-pass';
    await pumpScreen(tester, data, const SettingsScreen());
    await openAccountEntryAndTap(tester, 'アプリ運営用ログイン');
    expect(find.text('運営が用意したアカウントで入ります。新しい登録はできません。'), findsOneWidget);
    // 設定の画面にも検索の入力欄があるので、シートの中の入力欄に絞る。
    final fields = find.descendant(
      of: find.byType(AdminLoginForm),
      matching: find.byType(TextField),
    );
    Future<void> submit() async {
      await tester.ensureVisible(find.text('ログイン'));
      await tester.tap(find.text('ログイン'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // 両方に入れるまで、押せない。
    await submit();
    expect(data.userId, 'user-a');

    await tester.enterText(fields.at(0), 'review@example.com');
    await tester.enterText(fields.at(1), 'wrong');
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await submit();
      expect(find.text('メールアドレスかパスワードが違います'), findsOneWidget);
      ScaffoldMessenger.of(
        tester.element(fields.first),
      ).removeCurrentSnackBar();
      await tester.pumpAndSettle();
    }
    await submit();
    expect(find.text('しばらくしてからやり直してください'), findsOneWidget);
    expect(data.userId, 'user-a');
    // 入れないあいだは、正しいパスワードでも入れない。
    await tester.enterText(fields.at(1), 'right-pass');
    await submit();
    expect(data.userId, 'user-a');

    // 5分が過ぎたら入れる。画面とシートを閉じ、匿名のあいだのフォローを足し合わせる。
    data.passwordLoginLock = const PasswordLoginLock();
    await submit();
    expect(find.text('ログインしました'), findsOneWidget);
    expect(find.text('アプリ運営用ログイン'), findsNothing);
    expect(data.userId, 'user-admin');
    // 券は、試すたびに受け取り直す（違った5回と、入れた1回。入れないあいだは、受け取らない）。入れた回の券で移す。
    expect(data.mergeTokens, hasLength(6));
    expect(data.finishedMergeTokens, ['merge-6']);
    expect(data.follows.map((f) => f.creatorId), ['minato']);
    expect(find.text('ログアウト'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ログイン方法を結び付けた人の退会は、本人の確認のあとに行い、違うアカウントでは進まない', (tester) async {
    data
      ..onboardingDone = true
      ..loginMethods.add(
        const LoginMethod(
          provider: LoginProvider.google,
          identityId: 'google',
          accountLabel: 'me@example.com',
        ),
      )
      ..reauthResult = LoginResult.wrongAccount;
    await pumpScreen(tester, data, const WithdrawScreen());
    await tester.tap(find.text('退会する'));
    await tester.pumpAndSettle();
    expect(find.text('本人の確認'), findsOneWidget);
    expect(find.text('me@example.com'), findsOneWidget);
    await tester.tap(find.text('Google でログイン'));
    await tester.pumpAndSettle();
    expect(find.text('結び付けたアカウントで、ログインしてください'), findsOneWidget);
    expect(data.onboardingDone, isTrue);

    data.reauthResult = LoginResult.done;
    await tester.tap(find.text('Google でログイン'));
    await tester.pumpAndSettle();
    expect(find.text('本人の確認'), findsNothing);
    expect(data.onboardingDone, isFalse);
    await unmount(tester);
  });

  testWidgets('iPhone で Apple を結び付けた人の退会は、5分以内に済んでいても、Apple だけで確かめ、ひも付けを取り消す', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..loginMethods.addAll([googleLogin, appleLogin]);
    await pumpScreen(tester, data, const WithdrawScreen());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WithdrawScreen)),
    );
    await container
        .read(reauthProvider.notifier)
        .reauthenticate(data.loginMethods.first);
    expect(find.textContaining('この端末では、Apple'), findsNothing);
    await tester.tap(find.text('退会する'));
    await tester.pumpAndSettle();
    expect(find.text('本人の確認'), findsOneWidget);
    expect(find.text('Appleでサインイン'), findsOneWidget);
    expect(find.text('Google でログイン'), findsNothing);
    await tester.tap(find.text('Appleでサインイン'));
    await tester.pumpAndSettle();
    expect(data.reauthProviders, [LoginProvider.google, LoginProvider.apple]);
    expect(data.revokedAppleCode, 'apple-code');
    expect(data.onboardingDone, isFalse);
    await unmount(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Android で Apple を結び付けた人の退会は、ほかのログイン方法で確かめ、iPhone で外すように案内する', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..loginMethods.addAll([googleLogin, appleLogin]);
    await pumpScreen(tester, data, const WithdrawScreen());
    expect(find.textContaining('この端末では、Apple'), findsOneWidget);
    await tester.tap(find.text('退会する'));
    await tester.pumpAndSettle();
    expect(find.text('Appleでサインイン'), findsNothing);
    await tester.tap(find.text('Google でログイン'));
    await tester.pumpAndSettle();
    expect(data.revokedAppleCode, isNull);
    expect(data.onboardingDone, isFalse);
    await unmount(tester);
  });

  testWidgets('Android で Apple だけを結び付けた人には、iPhone で退会するように出し、退会させない', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..loginMethods.add(appleLogin);
    await pumpScreen(tester, data, const WithdrawScreen());
    expect(find.textContaining('iPhone で退会してください'), findsOneWidget);
    expect(find.textContaining('退会のあとに'), findsNothing);
    await tester.tap(find.text('退会する'));
    await tester.pumpAndSettle();
    expect(data.reauthCount, 0);
    expect(data.onboardingDone, isTrue);
    await unmount(tester);
  });

  testWidgets('発信者として登録した人には、設定にプロフィールカードも「発信者として登録する」も出さない', (tester) async {
    data.onboardingDone = true;
    data.ownedCreatorId = 'minato';
    await pumpScreen(tester, data, const SettingsScreen());
    expect(find.text('発信者として登録する'), findsNothing);
    expect(find.text('星野ミナト'), findsNothing);
    await unmount(tester);
  });

  testWidgets('下部ナビの左の丸から、発信者のタブ（発信者メニュー）を開く', (tester) async {
    data.ownedCreatorId = 'minato';
    await pumpHome(tester);
    final creatorTab = find.bySemanticsLabel('発信者メニュー');
    expect(creatorTab, findsOneWidget);
    await tester.tap(creatorTab);
    await tester.pumpAndSettle();
    // タブの本体なので、戻るは出さない。プロフィールカードは、設定から移したもの。
    expect(find.byTooltip('戻る'), findsNothing);
    expect(find.text('星野ミナト'), findsOneWidget);
    // プロフィールカードには、確認済みのチップを出さない。
    expect(find.text('確認済み'), findsNothing);
    // 確認が済んだ連携（YouTube・X）のアイコンを、並びの順に出す。
    expect(
      tester
          .widgetList<PlatformIcon>(find.byType(PlatformIcon))
          .map((i) => i.service),
      [SnsService.youtube, SnsService.x],
    );
    // プロフィールの編集は、カードの鉛筆から開くので、行を置かない。
    expect(find.byTooltip('プロフィールを編集する'), findsOneWidget);
    expect(find.text('プロフィールの編集'), findsNothing);
    // 自分のページと届いた数はカードにまとめたので、行と見出しを置かない（2026-11-19 本人）。
    expect(find.byKey(const ValueKey('creator-menu-reach')), findsOneWidget);
    expect(find.text('自分のページ'), findsNothing);
    // 並びは、シェア・連携・コンテンツ・プラン（2026-11-19 本人）。
    expect(find.text('シェア'), findsOneWidget);
    // 「追星に誘う」は、シェアの行ではなく、カードの共有のボタン（2026-11-19 本人）。
    expect(find.text('追星に誘う'), findsNothing);
    expect(find.byTooltip('追星に誘う'), findsOneWidget);
    expect(find.text('SNSリンク集'), findsOneWidget);
    // 見出しは送ると消えるので、メニューのスクロールを先に決めておく。
    final menuElement = tester.element(
      find
          .ancestor(of: find.text('シェア'), matching: find.byType(Scrollable))
          .first,
    );
    final menuScroll = find.byElementPredicate((e) => e == menuElement);
    await tester.scrollUntilVisible(
      find.text('投稿の管理'),
      200,
      scrollable: menuScroll,
    );
    expect(find.text('連携'), findsOneWidget);
    expect(find.text('連携・コンテンツ'), findsNothing);
    // SNS の連携と表示するコンテンツは、「SNS」の1つにまとめた（2026-11-19 本人）。
    expect(find.text('SNS'), findsOneWidget);
    expect(find.text('連携・表示する内容'), findsOneWidget);
    expect(find.text('SNS の連携'), findsNothing);
    expect(find.text('表示するコンテンツ'), findsNothing);
    // 「予定」グループには、「イベントの管理」も並ぶ（「カレンダー予定」の行はない）。下部ナビに隠れないよう、行まで送ってから押す。
    await tester.scrollUntilVisible(
      find.text('イベントの管理'),
      200,
      scrollable: menuScroll,
    );
    expect(find.text('イベントの管理'), findsOneWidget);
    // 見出しは「コンテンツ」（投稿の管理・イベントの管理）。「予定」の見出しはない。
    // 「予定のデフォルトの長さ」は無くした（2026-11-19 本人）。
    expect(find.text('コンテンツ'), findsOneWidget);
    expect(find.text('予定'), findsNothing);
    expect(find.text('カレンダー予定'), findsNothing);
    expect(find.text('予定のデフォルトの長さ'), findsNothing);
    await unmount(tester);
  });

  testWidgets('発信者のオーナーの退会では、発信者が90日残り、取り戻せると出す', (tester) async {
    await pumpScreen(tester, data, const WithdrawScreen());
    expect(find.textContaining('あなたの発信者は'), findsNothing);
    await unmount(tester);

    data.ownedCreatorId = 'minato';
    await pumpScreen(tester, data, const WithdrawScreen());
    expect(find.textContaining('あなたの発信者は、すぐに追星に表示されなくなり'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('X連携プランに加入中か、読み込めないときだけ、退会の前にサブスクを解約するよう案内する', (tester) async {
    const note = '退会しても、ストアのサブスクは解約されません。先に、サブスクの管理から解約してください。';
    // 加入なし。
    await pumpScreen(tester, data, const WithdrawScreen());
    expect(find.text(note), findsNothing);
    expect(find.text('サブスクの管理を開く'), findsNothing);
    await unmount(tester);

    // 加入中。ボタンで、ストアのサブスクの管理を開く（テストでは開けないので、知らせが出る）。
    data.serverSubscription = ServerPlanSubscription(
      xOptionExpiresAt: DateTime.now().add(const Duration(days: 3)),
    );
    await pumpScreen(tester, data, const WithdrawScreen());
    expect(find.text(note), findsOneWidget);
    await tester.tap(find.text('サブスクの管理を開く'));
    // URL を開く処理は、プラットフォームの応答を本当の時間で待つ。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('ページを開けませんでした'), findsOneWidget);
    // 案内があっても、退会はできる。
    expect(find.text('退会する'), findsOneWidget);
    await unmount(tester);

    // 読み込めない。
    data
      ..serverSubscription = ServerPlanSubscription.none
      ..serverSubscriptionFails = true;
    await pumpScreen(tester, data, const WithdrawScreen());
    expect(find.text(note), findsOneWidget);
    expect(find.text('サブスクの管理を開く'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('設定の検索で、出していない行の名前にだけ合うときは、「見つかりませんでした」を出す', (tester) async {
    data.onboardingDone = true;
    await pumpScreen(tester, data, const SettingsScreen());
    // 匿名なので「ログアウト」「ログイン方法」は出していない。
    for (final query in ['ログアウト', 'ログイン方法']) {
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();
      expect(find.text('見つかりませんでした'), findsOneWidget);
      expect(find.text('アカウント'), findsNothing);
    }

    // 出している行に合えば、出さない。
    await tester.enterText(find.byType(TextField), 'ログイン');
    await tester.pumpAndSettle();
    expect(find.text('見つかりませんでした'), findsNothing);
    expect(find.text('アカウント作成／ログイン'), findsOneWidget);
    await unmount(tester);

    // 発信者には「発信者として登録する」を出さないので、その名前にだけ合うときも、見つからない。
    data.ownedCreatorId = 'minato';
    await pumpScreen(tester, data, const SettingsScreen());
    await tester.enterText(find.byType(TextField), '発信者として');
    await tester.pumpAndSettle();
    expect(find.text('見つかりませんでした'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('自分の発信者を読めるまでは、「発信者として登録する」のカードを出さない', (tester) async {
    data
      ..onboardingDone = true
      ..ownedCreatorId = 'minato';
    await tester.pumpWidget(await testApp(data, const SettingsScreen()));
    // 最初のフレーム（まだ読めていない）。
    expect(find.text('発信者として登録する'), findsNothing);
    expect(find.text('発信者向け'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('発信者として登録する'), findsNothing);
    expect(find.text('発信者向け'), findsNothing);
    await unmount(tester);
  });

  testWidgets('サインインしていないときのお問い合わせは、ユーザー ID の代わりに、その旨を出し、コピーさせない', (
    tester,
  ) async {
    data
      ..onboardingDone = true
      ..userId = null;
    await pumpScreen(tester, data, const SettingsScreen());
    await tester.dragUntilVisible(
      find.text('お問い合わせ'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('お問い合わせ'));
    // メールアプリを開く処理は、プラットフォームの応答を本当の時間で待つ。
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    // テストにはメールアプリがないので、ダイアログを出す。
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('（サインインしていません）'), findsOneWidget);
    expect(find.text('ユーザーIDをコピー'), findsNothing);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('ログイン方法は、読み込み中は行をスケルトンにし、押せない', (tester) async {
    await tester.pumpWidget(await testApp(data, const LoginMethodsScreen()));
    // 最初のフレーム（まだ読めていない）。
    expect(find.byType(SkeletonIconRow), findsNWidgets(3));
    expect(find.text('結び付ける'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonIconRow), findsNothing);
    expect(find.text('結び付ける'), findsNWidgets(3));
    await unmount(tester);
  });

  testWidgets('ログイン方法で、結び付けと外すができ、最後の1つは外せない', (tester) async {
    await pumpScreen(tester, data, const LoginMethodsScreen());
    // テストは Android 扱いなので、Apple は出ない（iOS だけ）。
    expect(find.text('未設定'), findsNWidgets(3));
    expect(find.text('Apple'), findsNothing);
    await tester.tap(find.text('結び付ける').first);
    await tester.pumpAndSettle();
    expect(find.text('Googleのログインを結び付けました'), findsOneWidget);
    expect(find.text('google@example.com'), findsOneWidget);
    // 1つだけなので、外せない。
    expect(find.text('外す'), findsNothing);
    // 2つ目からは、結び付けたログイン方法で、本人を確かめてから結び付ける。
    await tester.tap(find.text('結び付ける').first);
    await tester.pumpAndSettle();
    expect(find.text('本人の確認'), findsOneWidget);
    await tester.tap(find.text('Google でログイン'));
    await tester.pumpAndSettle();
    expect(data.reauthCount, 1);
    expect(find.text('外す'), findsNWidgets(2));
    // 5分以内なので、外すときは、もう一度は求めない。
    await tester.tap(find.text('外す').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('外す').last);
    await tester.pumpAndSettle();
    expect(find.text('本人の確認'), findsNothing);
    expect(data.reauthCount, 1);
    expect(data.loginMethods.single.provider, LoginProvider.x);
    await unmount(tester);
  });

  testWidgets('Apple のログインは iOS だけで結び付けられ、ほかの端末では結び付け済みのときだけ出す', (
    tester,
  ) async {
    await pumpScreen(tester, data, const LoginMethodsScreen());
    expect(find.text('Apple'), findsOneWidget);
    await unmount(tester);
    // ここからは、iOS 以外の端末。もとの値には、variant が戻す。
    debugDefaultTargetPlatformOverride = null;

    data.loginMethods.add(appleLogin);
    await pumpScreen(tester, data, const LoginMethodsScreen());
    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('設定済み'), findsOneWidget);
    await unmount(tester);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('設定の「表示しない発信者」に人数を出し、一覧から「表示する」で戻せる', (tester) async {
    data.creators.add(
      const Creator(id: 'rei', name: '月城レイ', followerCounts: {}),
    );
    data.hiddenCreatorIds.addAll(['minato', 'rei']);
    await pumpScreen(tester, data, const SettingsScreen());
    await tester.dragUntilVisible(
      find.text('表示しない発信者'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('2人'), findsOneWidget);
    await tester.tap(find.text('表示しない発信者'));
    await tester.pumpAndSettle();
    expect(find.text('表示しないにした発信者は、検索やタイムラインに出ません。'), findsOneWidget);
    expect(find.text('@rei'), findsOneWidget);
    expect(find.text('@minato'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('hidden-rei')),
        matching: find.text('表示する'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('表示するように戻しました'), findsOneWidget);
    expect(data.hiddenCreatorIds, ['minato']);
    expect(find.text('@rei'), findsNothing);
    // フォローは戻さない。
    expect(data.follows, isEmpty);
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('1人'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('表示しない発信者が1人もいなければ、そのことを出す', (tester) async {
    await pumpScreen(tester, data, const HiddenCreatorsScreen());
    expect(find.text('表示しない発信者はいません'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('表示しない発信者を戻せなければ、知らせる', (tester) async {
    data
      ..hiddenCreatorIds.add('minato')
      ..hiddenWriteFails = true;
    await pumpScreen(tester, data, const HiddenCreatorsScreen());
    await tester.tap(find.text('表示する'));
    await tester.pumpAndSettle();
    expect(find.text('戻せませんでした'), findsOneWidget);
    expect(find.text('@minato'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('発信者メニューのカードの共有のボタンで、「追星に誘う」を開く（自分のページは開かない）', (tester) async {
    // 名前が長くても、アイコンは押し出されない（名前を「…」で切る）。
    data
      ..ownedCreatorId = 'minato'
      ..creators[0] = sampleCreator().copyWith(name: 'とても長い名前' * 10);
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('発信者メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('creator-menu-invite')));
    await tester.pumpAndSettle();
    expect(find.text('追星に誘う'), findsOneWidget);
    expect(find.byType(CreatorScreen), findsNothing);
    await unmount(tester);
  });

  testWidgets('発信者メニューのプロフィールカードで、自分の発信者ページを、発信者のタブのまま開く', (tester) async {
    data.ownedCreatorId = 'minato';
    await pumpHome(tester);
    await tester.tap(find.bySemanticsLabel('発信者メニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('creator-menu-own-page')));
    await tester.pumpAndSettle();
    final page = find.byType(CreatorScreen);
    expect(page, findsOneWidget);
    expect(tester.widget<CreatorScreen>(page).creatorId, 'minato');
    // 推しのタブへは移らず、発信者のタブの中に重ねる。
    expect(HomeTabs.tabOf(tester.element(page)), HomeTab.creator);
    await unmount(tester);
  });

  testWidgets('停止中の発信者は、発信者メニューのプロフィールカードに「停止中」を出す', (tester) async {
    data
      ..ownedCreatorId = 'minato'
      ..creators[0] = const Creator(
        id: 'minato',
        name: '星野ミナト',
        suspended: true,
      );
    await pumpScreen(
      tester,
      data,
      const CreatorMenuScreen(creatorId: 'minato'),
    );
    expect(find.text('停止中'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ログイン方法を読めなくても、ログイン中なら「ログアウト」を出し、行の「再試行」で読み直す', (tester) async {
    data
      ..loginMethods.add(googleLogin)
      ..failLoginMethods = true;
    await pumpScreen(tester, data, const SettingsScreen());
    expect(find.text('ログアウト'), findsOneWidget);
    expect(find.text('アカウント作成／ログイン'), findsNothing);
    expect(find.text('読み込めませんでした'), findsOneWidget);

    data.failLoginMethods = false;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('読み込めませんでした'), findsNothing);
    expect(find.text('再試行'), findsNothing);
    // 値は、結び付けたサービスの名前。
    expect(find.text('Google'), findsOneWidget);
    await unmount(tester);
  });
}
