import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/ui/creator/widgets/creator_cover.dart';
import 'package:oiboshi/ui/creator/widgets/creator_screen.dart';

import '../fakes.dart';
import 'screen_test_helpers.dart';

void main() {
  setUpScreenTests();

  final indicator = find.byKey(const ValueKey('creator-cover-flip-indicator'));

  testWidgets('自分の写真があれば、カバーを押すと裏返し、どちらの面かを覚える', (tester) async {
    data.creators[0] = sampleCreator().copyWith(
      coverUrl: 'https://example.com/creator.jpg',
    );
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now(),
        coverUrl: 'https://example.com/own.jpg',
      ),
    );
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    expect(indicator, findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('カバーを裏返す'), findsOneWidget);
    semantics.dispose();

    CreatorCover cover() =>
        tester.widget<CreatorCover>(find.byType(CreatorCover));
    expect(cover().showBack, isTrue);

    await tester.tap(find.byType(CreatorCover));
    await tester.pumpAndSettle();
    expect(cover().showBack, isFalse);
    expect(data.follows.first.showOwnCover, isFalse);

    await tester.tap(find.byType(CreatorCover));
    await tester.pumpAndSettle();
    expect(cover().showBack, isTrue);
    expect(data.follows.first.showOwnCover, isTrue);
    await unmount(tester);
  });

  testWidgets('カメラのメニューの「推しが設定したカバーに戻す」で、自分の写真を消す', (tester) async {
    data.follows.add(
      Follow(
        creatorId: 'minato',
        followedAt: DateTime.now(),
        coverUrl: 'https://example.com/own.jpg',
      ),
    );
    await pumpScreen(tester, data, const CreatorScreen(creatorId: 'minato'));
    await tester.tap(find.byTooltip('カバーを変える'));
    await tester.pumpAndSettle();
    expect(find.text('写真を選ぶ'), findsOneWidget);
    await tester.tap(find.text('推しが設定したカバーに戻す'));
    await tester.pumpAndSettle();
    expect(data.follows.first.coverUrl, isNull);
    expect(data.removedCovers, ['minato']);
    expect(indicator, findsNothing);
    await unmount(tester);
  });

  testWidgets('自分の写真がなければ、裏返せず、メニューは「写真を選ぶ」だけ', (tester) async {
    final picker = FakeImagePickerService();
    data.follows.add(sampleFollow());
    await pumpScreen(
      tester,
      data,
      const CreatorScreen(creatorId: 'minato'),
      picker: picker,
    );
    expect(indicator, findsNothing);
    await tester.tap(find.byTooltip('カバーを変える'));
    await tester.pumpAndSettle();
    expect(find.text('推しが設定したカバーに戻す'), findsNothing);
    await tester.tap(find.text('写真を選ぶ'));
    await tester.pumpAndSettle();
    expect(picker.picks, 1);
    await unmount(tester);
  });
}
