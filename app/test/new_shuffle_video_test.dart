import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/follow.dart';
import 'package:oiboshi/domain/models/oshi.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/domain/models/sns_service.dart';
import 'package:oiboshi/ui/home/widgets/home_shell.dart';

import 'helpers/samples.dart';

void main() {
  group('推しに新しい動画があるか（動画シャッフルの点。機能仕様書 4.3.5）', () {
    final now = DateTime(2026, 11, 19, 12);
    final oshis = [
      Oshi(
        follow: Follow(
          creatorId: 'minato',
          followedAt: now.subtract(const Duration(days: 10)),
          lastSeenAt: now.subtract(const Duration(days: 1)),
        ),
        creator: sampleCreator(),
      ),
    ];
    Post video({
      String creatorId = 'minato',
      SnsService source = SnsService.youtube,
      PostKind kind = PostKind.video,
      Duration ago = const Duration(hours: 1),
      bool isLiveContent = false,
    }) => samplePost(
      creatorId: creatorId,
      source: source,
      kind: kind,
      postedAt: now.subtract(ago),
      isLiveContent: isLiveContent,
    );
    bool check(List<Post> posts, {Set<String> removed = const {}}) =>
        anyNewShuffleVideo(oshis, posts, removed, now);

    test('最後に見たあとに投稿された YouTube の動画があれば、真', () {
      expect(check([video()]), isTrue);
    });

    test('最後に見る前の動画・3日より前の動画は、新しくない（ホームの NEW と同じ）', () {
      expect(check([video(ago: const Duration(days: 2))]), isFalse);
    });

    test('動画シャッフルに入らないもの（ショート・生配信の枠・ほかの SNS・消した投稿・推しでない人）は数えない', () {
      expect(check([video(kind: PostKind.short)]), isFalse);
      expect(check([video(isLiveContent: true)]), isFalse);
      expect(check([video(source: SnsService.x)]), isFalse);
      expect(check([video()], removed: {'yt:1'}), isFalse);
      expect(check([video(creatorId: 'hiyori')]), isFalse);
    });
  });
}
