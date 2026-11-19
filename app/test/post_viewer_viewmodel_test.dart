import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/provider_retry.dart';
import 'package:oiboshi/ui/core/view_models/playback_provider.dart';
import 'package:oiboshi/ui/post/view_models/post_viewer_viewmodel.dart';

import 'fakes.dart';

void main() {
  final posts = [samplePost(id: 'yt:1'), samplePost(id: 'yt:2')];
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(retry: noProviderRetry);
    addTearDown(container.dispose);
  });

  PostViewerViewModel open(PostViewerArgs args) {
    final sub = container.listen(postViewerViewModelProvider(args), (_, _) {});
    addTearDown(sub.close);
    return container.read(postViewerViewModelProvider(args).notifier);
  }

  test('同じ投稿と位置なら、同じキーとして扱う', () {
    final a = PostViewerArgs(posts: posts, initialIndex: 1);
    final b = PostViewerArgs(posts: [...posts], initialIndex: 1);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(PostViewerArgs(posts: posts, initialIndex: 0)));
    expect(a, isNot(PostViewerArgs(posts: [posts[1]], initialIndex: 1)));
    expect(identical(open(a), open(b)), isTrue);
  });

  test('最初の投稿だけ、小窓から開いたときの続きから始める', () {
    final vm = open(
      PostViewerArgs(
        posts: posts,
        initialIndex: 1,
        initialStart: const Duration(seconds: 30),
      ),
    );
    expect(vm.current.id, 'yt:2');
    expect(vm.startOf(1), const Duration(seconds: 30));
    expect(vm.startOf(0), Duration.zero);

    vm.showPost(0);
    expect(vm.current.id, 'yt:1');
  });

  test('「小窓にする」で、いまの投稿を見ていた位置から小窓で流す', () async {
    final vm = open(PostViewerArgs(posts: posts, initialIndex: 0));
    final author = sampleCreator();
    await vm.minimize(
      author: author,
      position: () async => const Duration(seconds: 12),
    );
    final playback = container.read(playbackProvider);
    expect(playback, isA<PostPlayback>());
    playback as PostPlayback;
    expect(playback.post.id, 'yt:1');
    expect(playback.author, author);
    expect(playback.start, const Duration(seconds: 12));
  });

  test('再生位置が分からなければ、最初から流す', () async {
    final vm = open(PostViewerArgs(posts: posts, initialIndex: 1));
    await vm.minimize(author: null, position: () async => null);
    final playback = container.read(playbackProvider) as PostPlayback;
    expect(playback.post.id, 'yt:2');
    expect(playback.start, Duration.zero);
  });
}
