import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/oshi/widgets/oshi_list_body.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/domain/models/oshi.dart';
import 'package:oiboshi/config/app_constants.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/ui/core/ui/app_buttons.dart';
import 'package:oiboshi/ui/core/ui/state_view.dart';
import 'package:oiboshi/ui/oshi/widgets/find_creators_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  testWidgets('推しリストは、配信中の推しに配信のタイトルを出し、フォロー中で解除できる', (tester) async {
    data.creators[0] = sampleCreator(live: sampleLive());
    data.follows.add(sampleFollow());
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    expect(find.text('1人フォロー中'), findsOneWidget);
    expect(find.text('配信中：朝の雑談'), findsOneWidget);
    await tester.tap(find.text('フォロー中'));
    await tester.pumpAndSettle();
    // 0人になったら、推しを探すへ誘う。
    expect(find.text('推しがいません'), findsOneWidget);
    expect(find.text('推しをフォローすると、ここに並びます。'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しリストのアイコンは、推しレーンと同じ印を出し、固定モードでも発信者ページを開き、ページのアイコンで配信を切り替える', (
    tester,
  ) async {
    final seen = DateTime.now().subtract(const Duration(hours: 2));
    data.creators[0] = sampleCreator(live: liveTitled('朝の雑談'));
    data.creators.addAll([
      hiyori(live: liveTitled('歌枠')),
      Creator(
        id: 'sora',
        name: '天野ソラ',
        latestPostAt: seen.add(const Duration(hours: 1)),
      ),
    ]);
    data.follows.addAll([
      sampleFollow(),
      sampleFollow('hiyori'),
      Follow(
        creatorId: 'sora',
        followedAt: seen.subtract(const Duration(days: 1)),
        lastSeenAt: seen,
      ),
    ]);
    usePhoneScreen(tester);
    await pumpHome(tester);
    final container = homeContainer(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await settleFrames(tester);
    final list = find.byType(OshiListBody);
    Iterable<OshiAvatar> avatars() => tester.widgetList<OshiAvatar>(
      find.descendant(of: list, matching: find.byType(OshiAvatar)),
    );
    // 配信中は「LIVE」、新着ありは「NEW」。赤いリングは、配信ビューアで流している推し（配信中の先頭）だけ。
    expect(avatars().map((a) => a.badge), [
      OshiBadge.live,
      OshiBadge.live,
      OshiBadge.newPost,
    ]);
    expect(avatars().map((a) => a.ring), [
      OshiRing.live,
      OshiRing.read,
      OshiRing.read,
    ]);

    // 固定モードで流している間も、推しリストのアイコンは、発信者ページを開く。小窓はそのまま流し、ページに映像を戻さない。
    container
        .read(playbackProvider.notifier)
        .play('minato', data.creators[0].live!);
    await settleFrames(tester);
    await tester.tap(
      find.descendant(of: list, matching: find.byType(OshiAvatar)).at(1),
    );
    await settleFrames(tester);
    // 配信中でも、いつもの発信者ページを開く。固定ビューアは、流していた配信のまま。
    expect(find.byType(CreatorScreen), findsOneWidget);
    expect(
      (container.read(playbackProvider)! as LivePlayback).creatorId,
      'minato',
    );
    // この推しの配信は流していないので、「固定ビューアで見る」を出す。押すと、この推しの配信に切り替える。
    await tester.tap(find.text('固定ビューアで見る'));
    await settleFrames(tester);
    expect(
      (container.read(playbackProvider)! as LivePlayback).creatorId,
      'hiyori',
    );
    expect(find.text('固定ビューアで見る'), findsNothing);
    await unmount(tester);
  });

  testWidgets('推しを探すで、結果がなければ入力した言葉を入れて出す', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('推しを探す'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ほしのミナ');
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();
    expect(find.text('見つかりませんでした'), findsOneWidget);
    expect(find.textContaining('「ほしのミナ」に合う推しは'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しリストは、検索に合う推しがいなければ、入力した言葉を入れて出す', (tester) async {
    data.follows.add(sampleFollow());
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'いない人');
    await tester.pumpAndSettle();
    expect(find.text('見つかりませんでした'), findsOneWidget);
    expect(find.text('「いない人」に合う推しは、フォロー中にいません。'), findsOneWidget);
    // 件数は、フォロー中の全員の数のまま。
    expect(find.text('1人フォロー中'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しリストは、推しが0人なら、推しを探すへ誘う', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    expect(find.text('推しがいません'), findsOneWidget);
    await tester.tap(find.widgetWithText(PrimaryButton, '推しを探す'));
    await tester.pumpAndSettle();
    expect(find.byType(FindCreatorsScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しを探すは、打ち終わってからサーバーで探し、前の結果を出したまま待つ', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('推しを探す'));
    await tester.pumpAndSettle();
    expect(find.text('おすすめ'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'み');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'みな');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'みなと');
    await tester.pump(const Duration(milliseconds: 100));
    // 待っている間は、問い合わせず、前の一覧を出したまま。
    expect(data.searches, isEmpty);
    expect(find.text('星野ミナト'), findsOneWidget);
    // 結果が届くまでは、見出しも、おすすめと一緒に残す。
    expect(find.text('おすすめ'), findsOneWidget);

    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();
    expect(data.searches, ['みなと']);
    expect(find.text('おすすめ'), findsNothing);
    expect(find.text('星野ミナト'), findsOneWidget);
    await unmount(tester);
  });

  /// 推しを探すの一覧で、[a] が [b] より上にあるか。
  bool above(WidgetTester tester, String a, String b) =>
      tester.getTopLeft(find.text(a)).dy < tester.getTopLeft(find.text(b)).dy;

  testWidgets('推しを探すのおすすめは、推しのタイプに合う発信者、優先の発信者の順に出し、フォロー済みを出さない', (
    tester,
  ) async {
    data.creators[0] = sampleCreator().copyWith(types: ['game']);
    data.creators.addAll([
      const Creator(id: 'z1', name: 'あいう'),
      const Creator(id: 's1', name: '歌の人', types: ['singing']),
      const Creator(id: 'g1', name: 'ゲーム好き', types: ['game', 'chat']),
    ]);
    data.featured.add('s1');
    data.follows.add(sampleFollow());
    await pumpScreen(tester, data, const FindCreatorsScreen());
    expect(find.text('おすすめ'), findsOneWidget);
    expect(find.text('星野ミナト'), findsNothing);
    expect(above(tester, 'ゲーム好き', '歌の人'), isTrue);
    expect(above(tester, '歌の人', 'あいう'), isTrue);
    expect(data.recommendCount, 1);

    // フォローしても、行は消さず、読み直さない。
    await tester.tap(find.text('フォロー').first);
    await tester.pumpAndSettle();
    expect(find.text('ゲーム好き'), findsOneWidget);
    expect(find.text('フォロー中'), findsOneWidget);

    // 検索して、言葉を消すと、同じおすすめに戻る（選び直さない）。
    await tester.enterText(find.byType(TextField), 'あいう');
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();
    expect(find.text('おすすめ'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('おすすめ'), findsOneWidget);
    expect(find.text('ゲーム好き'), findsOneWidget);
    expect(data.recommendCount, 1);
    await unmount(tester);
  });

  testWidgets('推しがいなければ、おすすめは優先の発信者を先に出す', (tester) async {
    data.creators.add(const Creator(id: 's1', name: '優先の人'));
    data.featured.add('s1');
    await pumpScreen(tester, data, const FindCreatorsScreen());
    expect(above(tester, '優先の人', '星野ミナト'), isTrue);
    await unmount(tester);
  });

  testWidgets('推しを探すは、おすすめが0人なら、見出しを出さない', (tester) async {
    data.creators.clear();
    await pumpScreen(tester, data, const FindCreatorsScreen());
    expect(find.text('おすすめ'), findsNothing);
    expect(find.text('見つかりませんでした'), findsNothing);
    await unmount(tester);
  });

  /// 推しリストの、一覧の場所を引き下げる。
  Future<void> pullDown(WidgetTester tester) async {
    await tester.fling(find.byType(StateView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
  }

  testWidgets('推しリストは、推しが0人でも、引き下げで読み直せる', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    expect(find.text('推しがいません'), findsOneWidget);
    data.follows.add(sampleFollow());
    await pullDown(tester);
    expect(find.text('1人フォロー中'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しリストは、検索に合う推しがいなくても、引き下げで読み直せる', (tester) async {
    data.follows.add(sampleFollow());
    data.creators.add(hiyori());
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ひより');
    await tester.pumpAndSettle();
    expect(find.text('見つかりませんでした'), findsOneWidget);
    data.follows.add(sampleFollow('hiyori'));
    await pullDown(tester);
    expect(find.text('見つかりませんでした'), findsNothing);
    expect(find.text('2人フォロー中'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しリストは、読み込めなくても、引き下げで読み直せ、「もう一度試す」も残す', (tester) async {
    data
      ..follows.add(sampleFollow())
      ..failReads = true;
    await pumpHome(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await tester.pumpAndSettle();
    expect(find.text('もう一度試す'), findsOneWidget);
    data.failReads = false;
    await pullDown(tester);
    expect(find.text('1人フォロー中'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しリストのヘッダーは、固定ビューアを出している間だけ、一覧と一緒に上へ隠れる', (tester) async {
    for (var i = 0; i < 20; i++) {
      data.creators.add(Creator(id: 'c$i', name: '推し$i'));
      data.follows.add(sampleFollow('c$i'));
    }
    usePhoneScreen(tester);
    await pumpHome(tester);
    final container = homeContainer(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await settleFrames(tester);
    final list = find.descendant(
      of: find.byType(OshiListBody),
      matching: find.byType(CustomScrollView),
    );
    // 題名は出さないので、いちばん上の「推しを探す」のボタンで、ヘッダーが残っているかを見る。
    final title = find.byTooltip('推しを探す');
    // 閉じている間は、スクロールしても、ヘッダーを上に残す。
    await tester.drag(list, const Offset(0, -400));
    await settleFrames(tester);
    expect(title.hitTestable(), findsOneWidget);

    // スクロールしたまま固定ビューアを出すと、ヘッダーは隠れたところから始める。
    double offset() => tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        )
        .position
        .pixels;
    final before = offset();
    expect(before, greaterThan(0));
    container.read(fixedViewerEmptyProvider.notifier).set(true);
    await settleFrames(tester);
    expect(title.hitTestable(), findsNothing);
    expect(offset(), before);

    // 上まで戻すと、ヘッダーがまた見える。
    await tester.drag(list, const Offset(0, 2000));
    await settleFrames(tester);
    expect(title.hitTestable(), findsOneWidget);

    // 下にスクロールすると、一覧と一緒に隠れる。
    await tester.drag(list, const Offset(0, -400));
    await settleFrames(tester);
    expect(title.hitTestable(), findsNothing);

    // 閉じると、また上に固定する。
    container.read(fixedViewerEmptyProvider.notifier).set(false);
    await settleFrames(tester);
    expect(title.hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('推しを探すのヘッダーと検索も、固定ビューアを出している間だけ、一覧と一緒に上へ隠れる', (tester) async {
    for (var i = 0; i < 20; i++) {
      data.creators.add(Creator(id: 'c$i', name: '推し$i'));
    }
    usePhoneScreen(tester);
    await pumpHome(tester);
    final container = homeContainer(tester);
    await tester.tap(find.byIcon(Icons.star_outline));
    await settleFrames(tester);
    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
    await settleFrames(tester);
    final list = find.descendant(
      of: find.byType(FindCreatorsScreen),
      matching: find.byType(ListView),
    );
    final search = find.descendant(
      of: find.byType(FindCreatorsScreen),
      matching: find.byType(TextField),
    );

    // 閉じている間は、ヘッダーと検索を上に残す。
    await tester.drag(list, const Offset(0, -400));
    await settleFrames(tester);
    expect(search.hitTestable(), findsOneWidget);

    // 出している間は、一覧と一緒に隠れ、上まで戻すと見える。
    container.read(fixedViewerEmptyProvider.notifier).set(true);
    await settleFrames(tester);
    expect(search.hitTestable(), findsNothing);
    await tester.drag(list, const Offset(0, 2000));
    await settleFrames(tester);
    expect(search.hitTestable(), findsOneWidget);
    await unmount(tester);
  });
}
