import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/view_models/audio_focus_provider.dart';

void main() {
  test('前の動画が1つでも音を取っていれば、配信の音を消し、全部離したら戻す', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final focus = container.read(audioFocusProvider.notifier);
    final a = Object();
    final b = Object();

    expect(container.read(liveAudioSuppressedProvider), isFalse);
    focus.acquire(a);
    focus.acquire(b);
    focus.acquire(a);
    expect(container.read(liveAudioSuppressedProvider), isTrue);
    focus.release(a);
    expect(container.read(liveAudioSuppressedProvider), isTrue);
    focus.release(b);
    expect(container.read(liveAudioSuppressedProvider), isFalse);
  });
}
