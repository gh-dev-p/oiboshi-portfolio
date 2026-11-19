import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/creator.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/core/themes/app_colors.dart';
import 'package:oiboshi/ui/core/ui/link_text.dart';
import 'package:oiboshi/ui/core/ui/oshi_avatar.dart';
import 'package:oiboshi/ui/core/ui/post_cards.dart';
import 'package:oiboshi/ui/core/ui/sns_style.dart';

import 'fakes.dart';
import 'helpers/widget_helpers.dart';

void main() {
  const author = Creator(
    id: 'hiyori',
    name: '桜井ひより',
    linkedAccounts: {
      SnsService.instagram: CreatorAccount(
        service: SnsService.instagram,
        account: 'hiyori_sakurai',
        verified: true,
      ),
      SnsService.x: CreatorAccount(
        service: SnsService.x,
        account: 'hiyori_x',
        verified: true,
      ),
    },
  );

  Future<void> pumpCard(WidgetTester tester, Post post) => tester.pumpWidget(
    localizedApp(
      Scaffold(
        body: SingleChildScrollView(
          child: PostCard(
            post: post,
            author: author,
            now: DateTime.now(),
            onTap: () {},
          ),
        ),
      ),
    ),
  );

  test('サーバーの行から、いいね数とコメント数を読む', () {
    final post = Post.fromRow({
      'id': 'ig:1',
      'creator_id': 'hiyori',
      'source': 'instagram',
      'kind': 'image',
      'text': 'モンブラン',
      'posted_at': '2026-10-14T00:00:00Z',
      'permalink': 'https://example.com',
      'like_count': 300,
      'comment_count': 12,
    });
    expect(post.likeCount, 300);
    expect(post.commentCount, 12);
  });

  test('動画本体を再生するのは、Instagram の動画と X の動画（GIF を含む）だけ', () {
    for (final (source, kind, expected) in [
      (SnsService.instagram, PostKind.reel, true),
      (SnsService.instagram, PostKind.video, true),
      (SnsService.instagram, PostKind.image, false),
      (SnsService.x, PostKind.video, true),
      (SnsService.x, PostKind.image, false),
      (SnsService.youtube, PostKind.video, false),
    ]) {
      expect(
        samplePost(source: source, kind: kind).isFileVideo,
        expected,
        reason: '$source $kind',
      );
    }
  });

  test('X の、画像と動画が2つ以上ある投稿も、カルーセルとして読む', () {
    final post = Post.fromRow({
      'id': 'x:4',
      'creator_id': 'hiyori',
      'source': 'x',
      'kind': 'carousel',
      'text': 'まとめて',
      'posted_at': '2026-10-14T00:00:00Z',
      'permalink': 'https://x.com/someone/status/4',
      'thumbnail_url': 'https://pbs.example/1.jpg',
      'media': [
        {'type': 'image', 'image_url': 'https://pbs.example/1.jpg'},
        {
          'type': 'video',
          'image_url': 'https://pbs.example/2.jpg',
          'video_url': 'https://video.example/2.mp4',
        },
      ],
    });
    expect(post.isCarousel, isTrue);
    expect(post.isFileVideo, isFalse);
    expect(post.mediaAt(0).isFileVideo, isFalse);
    expect(post.mediaAt(1).isFileVideo, isTrue);
    expect(post.mediaAt(1).videoUrl, 'https://video.example/2.mp4');
  });

  test('サーバーの行から、カルーセルの中身を読む。中身のない投稿は空', () {
    final post = Post.fromRow({
      'id': 'ig:2',
      'creator_id': 'hiyori',
      'source': 'instagram',
      'kind': 'carousel',
      'text': '',
      'posted_at': '2026-10-14T00:00:00Z',
      'permalink': 'https://example.com',
      'thumbnail_url': 'https://cdn.example/1.jpg',
      'media': [
        {'type': 'image', 'image_url': 'https://cdn.example/1.jpg'},
        {
          'type': 'video',
          'image_url': 'https://cdn.example/2.jpg',
          'video_url': 'https://cdn.example/2.mp4',
        },
      ],
    });
    expect(post.isCarousel, isTrue);
    final video = post.mediaAt(1);
    expect(video.isFileVideo, isTrue);
    expect(video.thumbnailUrl, 'https://cdn.example/2.jpg');
    expect(video.videoUrl, 'https://cdn.example/2.mp4');
    expect(post.mediaAt(0).kind, PostKind.image);
    expect(post.mediaAt(0).id, isNot(post.mediaAt(1).id));
    expect(samplePost().media, isEmpty);
    expect(samplePost().isCarousel, isFalse);
  });

  testWidgets('SNS を問わず、投稿者の行（名前・プラットフォームのアイコン）を上に出し、本文を続ける', (tester) async {
    for (final (source, kind) in [
      (SnsService.youtube, PostKind.video),
      (SnsService.instagram, PostKind.reel),
      (SnsService.x, PostKind.text),
    ]) {
      await pumpCard(
        tester,
        samplePost(source: source, kind: kind, text: '本文 ${source.name}'),
      );
      // X の投稿も、推しの名前を出す（右上に、X での名前。取れていなければ @ユーザー名）。
      const name = '桜井ひより';
      expect(find.text(name), findsOneWidget);
      if (source == SnsService.x) {
        expect(find.text('@hiyori_x'), findsOneWidget);
      }
      final icon = tester.widget<PlatformIcon>(find.byType(PlatformIcon));
      expect(icon.service, source);
      expect(find.byType(SourceBadge), findsNothing);
      expect(find.text('本文 ${source.name}'), findsOneWidget);
      final nameY = tester.getTopLeft(find.text(name)).dy;
      final textY = tester.getTopLeft(find.text('本文 ${source.name}')).dy;
      expect(nameY, lessThan(textY));
    }
  });

  testWidgets('Instagram は、いいね数とコメント数を出す。いいね数が隠されていれば、アイコンだけ出す', (
    tester,
  ) async {
    await pumpCard(
      tester,
      samplePost(
        source: SnsService.instagram,
        kind: PostKind.reel,
        text: '秋限定のモンブラン',
        likeCount: 300,
        commentCount: 12,
      ),
    );
    expect(find.text('300'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await pumpCard(
      tester,
      samplePost(
        source: SnsService.instagram,
        kind: PostKind.image,
        commentCount: 3,
      ),
    );
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('YouTube は、再生回数だけを出す', (tester) async {
    await pumpCard(
      tester,
      samplePost(viewCount: 12000, likeCount: 50, commentCount: 4),
    );
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.text('4'), findsNothing);
  });

  testWidgets('X は、右上に X の投稿者と X のロゴ、推しの名前の下に時間と「Xで見る」を出し、数は出さない', (
    tester,
  ) async {
    await pumpCard(
      tester,
      samplePost(
        source: SnsService.x,
        kind: PostKind.text,
        text: 'セトリ考え中 @friend_1 #推し活',
        viewCount: 5000,
        likeCount: 437,
        commentCount: 17,
      ),
    );
    // X のプロフィールをまだ取れていなければ、X での表示名の代わりに @ユーザー名を出す。
    expect(find.text('@hiyori_x'), findsOneWidget);
    expect(find.text('桜井ひより'), findsOneWidget);
    final viewOnX = find.textContaining('Xで見る', findRichText: true);
    expect(viewOnX, findsOneWidget);
    expect(find.text('17'), findsNothing);
    expect(find.text('437'), findsNothing);
    expect(find.text('5,000'), findsNothing);
    final logo = find.byWidgetPredicate(
      (w) => w is PlatformIcon && w.service == SnsService.x,
    );
    expect(logo, findsOneWidget);
    final oshiRight = tester.getTopRight(find.text('桜井ひより')).dx;
    final textTop = tester.getTopLeft(find.byType(LinkText)).dy;
    // 「Xで見る」は、推しの名前の下。
    expect(
      tester.getTopLeft(viewOnX).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('桜井ひより')).dy),
    );
    // X の投稿者は、右上（推しの名前より右、本文より上）。ロゴは、その右。
    expect(
      tester.getTopLeft(find.text('@hiyori_x')).dx,
      greaterThan(oshiRight),
    );
    expect(
      tester.getBottomLeft(find.text('@hiyori_x')).dy,
      lessThanOrEqualTo(textTop),
    );
    expect(
      tester.getTopLeft(logo).dx,
      greaterThan(tester.getTopRight(find.text('@hiyori_x')).dx),
    );
    expect(tester.getBottomLeft(logo).dy, lessThanOrEqualTo(textTop));
  });

  testWidgets('X の投稿は、右上に、左から表示名／@ユーザー名の2段、X でのアイコン、X のロゴを並べる', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: samplePost(source: SnsService.x, kind: PostKind.text),
              author: const Creator(
                id: 'hiyori',
                name: '桜井ひより',
                avatarUrl: 'https://example.com/oiboshi.png',
                linkedAccounts: {
                  SnsService.x: CreatorAccount(
                    service: SnsService.x,
                    account: 'hiyori_x',
                    verified: true,
                    profileName: 'ひより🌸10/25ライブ',
                    profileUsername: 'Hiyori_New',
                    profileImageUrl: 'https://pbs.twimg.com/a_200x200.jpg',
                  ),
                },
              ),
              now: DateTime.now(),
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    final name = find.text('ひより🌸10/25ライブ');
    final user = find.text('@Hiyori_New');
    expect(name, findsOneWidget);
    expect(user, findsOneWidget);
    expect(find.text('桜井ひより'), findsOneWidget);
    expect(find.text('@hiyori_x'), findsNothing);
    // 表示名と @ユーザー名は縦に並ぶ（左をそろえる）。
    expect(tester.getTopLeft(name).dx, tester.getTopLeft(user).dx);
    expect(tester.getTopLeft(user).dy, tester.getBottomLeft(name).dy);
    // 灰色の小さい字。
    final c = AppColors.light;
    for (final f in [name, user]) {
      final style = tester.widget<Text>(f).style!;
      expect(style.color, c.textMuted);
      expect(style.fontSize, lessThan(11));
      expect(style.fontSize, greaterThanOrEqualTo(10));
    }
    // 2段の右に X でのアイコン、そのさらに右（右の端）に X のロゴ。どちらも同じ大きさで、2段の文字と同じ高さ。
    final xRow = find.byType(XAuthorLine);
    final avatar = find.descendant(
      of: xRow,
      matching: find.byType(AvatarImage),
    );
    final logo = find.descendant(of: xRow, matching: find.byType(PlatformIcon));
    expect(tester.getSize(avatar), tester.getSize(logo));
    expect(
      tester.getTopLeft(avatar).dx,
      greaterThanOrEqualTo(tester.getTopRight(name).dx),
    );
    expect(
      tester.getTopLeft(logo).dx,
      greaterThanOrEqualTo(tester.getTopRight(avatar).dx),
    );
    expect(tester.getTopRight(logo).dx, tester.getTopRight(xRow).dx);
    final textMid =
        (tester.getTopLeft(name).dy + tester.getBottomLeft(user).dy) / 2;
    expect(tester.getCenter(avatar).dy, closeTo(textMid, 0.5));
    expect(tester.getCenter(logo).dy, closeTo(textMid, 0.5));
    final textHeight =
        tester.getBottomLeft(user).dy - tester.getTopLeft(name).dy;
    expect(tester.getSize(avatar).height, closeTo(textHeight, 0.5));
    expect(tester.getSize(logo).height, closeTo(textHeight, 0.5));
    final images = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<NetworkImage>()
        .map((i) => i.url);
    expect(images, contains('https://pbs.twimg.com/a_200x200.jpg'));
    expect(images, contains('https://example.com/oiboshi.png'));
  });

  testWidgets('X の投稿者は、アイコンの2倍の幅に入りきらなければ、表示名と @ユーザー名を「…」で切る', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: WithXAuthorLine(
                leading: const Text('推し'),
                author: const Creator(
                  id: 'hiyori',
                  name: '桜井ひより',
                  linkedAccounts: {
                    SnsService.x: CreatorAccount(
                      service: SnsService.x,
                      account: 'hiyori_x',
                      verified: true,
                      profileName: 'とても長い表示名のひより🌸10/25ライブ告知中',
                      profileUsername: 'Hiyori_Long_Name',
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // 表示名・@ユーザー名の文字の欄は、アイコンの幅の2倍まで。
    expect(XAuthorLine.textMaxWidth, XAuthorLine.iconSize * 2);
    for (final text in ['とても長い表示名のひより🌸10/25ライブ告知中', '@Hiyori_Long_Name']) {
      expect(
        tester.getSize(find.text(text)).width,
        lessThanOrEqualTo(XAuthorLine.textMaxWidth),
      );
    }
    for (final text in ['とても長い表示名のひより🌸10/25ライブ告知中', '@Hiyori_Long_Name']) {
      final widget = tester.widget<Text>(find.text(text));
      expect(widget.overflow, TextOverflow.ellipsis);
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(fontSize: XAuthorLine.fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      expect(tester.getSize(find.text(text)).width, lessThan(painter.width));
    }
  });

  testWidgets('X の投稿も、推しの名前を押すと、投稿者の行を押したときの動きになる', (tester) async {
    var authorTaps = 0;
    var postTaps = 0;
    await tester.pumpWidget(
      localizedApp(
        Scaffold(
          body: SingleChildScrollView(
            child: PostCard(
              post: samplePost(source: SnsService.x, kind: PostKind.text),
              author: author,
              now: DateTime.now(),
              onTap: () => postTaps++,
              onAuthorTap: () => authorTaps++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('桜井ひより'));
    expect(authorTaps, 1);
    expect(postTaps, 0);
  });
}
