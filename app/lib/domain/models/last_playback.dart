import 'dart:convert';

/// 固定ビューアで最後に流していたもの（機能仕様書 4.3.5）。端末内に覚え、次に固定ビューアを開いたときに続きから流す。
sealed class LastPlayback {
  const LastPlayback();

  /// 端末内に覚えた文字列から読む。読めなければ null。
  static LastPlayback? decode(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) return null;
      return switch (json['kind']) {
        'live' => switch (json['creatorId']) {
          final String id when id.isNotEmpty => LastLive(id),
          _ => null,
        },
        'video' => switch ((json['postId'], json['positionMs'])) {
          (final String id, final int ms) when id.isNotEmpty => LastVideo(
            postId: id,
            position: Duration(milliseconds: ms < 0 ? 0 : ms),
          ),
          _ => null,
        },
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  /// 端末内に覚える文字列。
  String encode();
}

/// 推しの配信。続きの位置はない。次に開いたとき、まだ配信中なら、その配信を流す。
class LastLive extends LastPlayback {
  const LastLive(this.creatorId);

  final String creatorId;

  @override
  String encode() => jsonEncode({'kind': 'live', 'creatorId': creatorId});

  @override
  bool operator ==(Object other) =>
      other is LastLive && other.creatorId == creatorId;

  @override
  int get hashCode => creatorId.hashCode;
}

/// 推しの YouTube の動画と、その再生位置。
class LastVideo extends LastPlayback {
  const LastVideo({required this.postId, required this.position});

  final String postId;
  final Duration position;

  @override
  String encode() => jsonEncode({
    'kind': 'video',
    'postId': postId,
    'positionMs': position.inMilliseconds,
  });

  @override
  bool operator ==(Object other) =>
      other is LastVideo &&
      other.postId == postId &&
      other.position == position;

  @override
  int get hashCode => Object.hash(postId, position);
}
