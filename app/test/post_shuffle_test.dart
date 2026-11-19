import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/post.dart';
import 'package:oiboshi/ui/core/view_models/post_shuffle_provider.dart';

import 'helpers/samples.dart';

Post _video(String creatorId, int n) => samplePost(
  id: 'yt:$creatorId-$n',
  creatorId: creatorId,
  text: '',
  postedAt: DateTime(2026, 1, 1),
  permalink: 'https://youtu.be/$creatorId-$n',
);

void main() {
  test('推しが2人以上なら、同じ推しを続けない（周のつなぎ目でも）', () {
    for (var seed = 0; seed < 50; seed++) {
      final shuffle = PostShuffle([
        for (var n = 0; n < 20; n++) _video('a', n),
        for (var n = 0; n < 3; n++) _video('b', n),
        _video('c', 0),
      ], random: Random(seed));
      String? last;
      for (var i = 0; i < 100; i++) {
        final post = shuffle.next()!;
        expect(post.creatorId, isNot(last), reason: 'seed $seed, $i 本目');
        last = post.creatorId;
      }
    }
  });

  test('1周で、推しを1人1本ずつ流す（多く投稿する推しに偏らない）', () {
    final shuffle = PostShuffle([
      for (var n = 0; n < 20; n++) _video('a', n),
      _video('b', 0),
      _video('c', 0),
    ], random: Random(1));
    for (var round = 0; round < 5; round++) {
      final creators = {for (var i = 0; i < 3; i++) shuffle.next()!.creatorId};
      expect(creators, {'a', 'b', 'c'});
    }
  });

  test('推しの動画は、全部流してから繰り返す', () {
    final shuffle = PostShuffle([
      for (var n = 0; n < 4; n++) _video('a', n),
    ], random: Random(2));
    final first = {for (var i = 0; i < 4; i++) shuffle.next()!.id};
    expect(first, hasLength(4));
  });

  test('前に戻ると、流した順にたどる', () {
    final shuffle = PostShuffle([
      for (var n = 0; n < 5; n++) _video('a', n),
      for (var n = 0; n < 5; n++) _video('b', n),
    ], random: Random(3));
    expect(shuffle.hasPrevious, isFalse);
    final played = [for (var i = 0; i < 4; i++) shuffle.next()!];
    expect(shuffle.previous(), played[2]);
    expect(shuffle.previous(), played[1]);
    expect(shuffle.next(), played[2]);
    expect(shuffle.next(), played[3]);
    expect(shuffle.current, played[3]);
  });

  test('動画がなければ、何も流さない', () {
    final shuffle = PostShuffle(const []);
    expect(shuffle.isEmpty, isTrue);
    expect(shuffle.next(), isNull);
  });

  test('startAt：指定した動画から始め、その推しはこの周でもう選ばない。なければ何もしない', () {
    for (var seed = 0; seed < 20; seed++) {
      final shuffle = PostShuffle([
        for (var n = 0; n < 3; n++) _video('a', n),
        for (var n = 0; n < 3; n++) _video('b', n),
        _video('c', 0),
      ], random: Random(seed));
      expect(shuffle.startAt('yt:x-0'), isNull);
      expect(shuffle.startAt('yt:a-1')?.id, 'yt:a-1');
      expect(shuffle.current?.id, 'yt:a-1');
      // 2回目は、もう始めているので何もしない。
      expect(shuffle.startAt('yt:b-0'), isNull);
      final round = [shuffle.next()!, shuffle.next()!];
      expect(round.map((p) => p.creatorId).toSet(), {'b', 'c'});
      // a の残りの2本を流し終えるまで、始めた動画は流さない。
      final next = [for (var i = 0; i < 6; i++) shuffle.next()!];
      final fromA = next.where((p) => p.creatorId == 'a').take(2);
      expect(fromA.map((p) => p.id), isNot(contains('yt:a-1')));
      expect(shuffle.previous(), isNotNull);
    }
  });
}
