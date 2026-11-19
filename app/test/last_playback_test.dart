import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/last_playback.dart';

void main() {
  test('配信と動画を、文字列にして読み戻せる', () {
    const live = LastLive('minato');
    const video = LastVideo(postId: 'yt:1', position: Duration(seconds: 83));
    expect(LastPlayback.decode(live.encode()), live);
    expect(LastPlayback.decode(video.encode()), video);
  });

  test('読めない文字列は null', () {
    expect(LastPlayback.decode(null), isNull);
    expect(LastPlayback.decode(''), isNull);
    expect(LastPlayback.decode('壊れた'), isNull);
    expect(LastPlayback.decode('[]'), isNull);
    expect(LastPlayback.decode('{"kind":"live","creatorId":""}'), isNull);
    expect(LastPlayback.decode('{"kind":"video","postId":"yt:1"}'), isNull);
    expect(LastPlayback.decode('{"kind":"other"}'), isNull);
  });
}
