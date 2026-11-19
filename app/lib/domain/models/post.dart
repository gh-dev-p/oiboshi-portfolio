import '../../utils/server_time.dart';
import 'enum_name.dart';
import 'sns_service.dart';

/// 投稿の種類。画面に出す名前は、View で `AppLocalizations.postKindName` から引く。
enum PostKind { video, short, image, reel, carousel, text, other }

/// 投稿。`posts` テーブルの1行。
class Post {
  const Post({
    required this.id,
    required this.creatorId,
    required this.source,
    required this.kind,
    required this.text,
    required this.postedAt,
    required this.permalink,
    this.thumbnailUrl,
    this.videoUrl,
    this.media = const [],
    this.viewCount,
    this.likeCount,
    this.commentCount,
    this.isLiveContent = false,
  });

  factory Post.fromRow(Map<String, dynamic> row) => Post(
    id: row['id'] as String,
    creatorId: row['creator_id'] as String,
    source: SnsService.fromName(row['source'] as String?) ?? SnsService.youtube,
    kind: PostKind.values.byNameOrNull(row['kind']) ?? PostKind.other,
    text: (row['text'] as String?) ?? '',
    postedAt: parseTime(row['posted_at'] as String)!,
    permalink: row['permalink'] as String,
    thumbnailUrl: row['thumbnail_url'] as String?,
    videoUrl: row['video_url'] as String?,
    media: [
      for (final m in (row['media'] as List?) ?? const [])
        PostMedia.fromJson(m as Map<String, dynamic>),
    ],
    viewCount: row['view_count'] as int?,
    likeCount: row['like_count'] as int?,
    commentCount: row['comment_count'] as int?,
    isLiveContent: row['live_status'] != null,
  );

  final String id;
  final String creatorId;
  final SnsService source;
  final PostKind kind;

  /// YouTube はタイトル、Instagram はキャプション、X は本文。
  final String text;
  final DateTime postedAt;
  final String permalink;
  final String? thumbnailUrl;

  /// 動画本体の URL。Instagram の動画（リール）と X の動画（GIF を含む）だけ。取れなかった動画は空。
  final String? videoUrl;

  /// カルーセルの中身（1枚目からの順）。Instagram のカルーセルと、画像・動画が2つ以上ある X の投稿だけ。ほかは空。
  final List<PostMedia> media;
  final int? viewCount;

  /// いいね数。Instagram と X だけ。投稿者が隠しているときは空。
  final int? likeCount;

  /// コメント数（X はリプライ数）。Instagram と X だけ。
  final int? commentCount;

  /// 生配信（配信中・配信予定）の枠か（`posts.live_status`）。YouTube の配信枠は RSS に動画として入るので、
  /// サーバーが中身（`liveBroadcastContent`）で印を付ける。終わった配信のアーカイブは、動画として扱う（偽）。
  /// 固定ビューアの動画シャッフルには入れない（機能仕様書 4.3.5.1）。
  final bool isLiveContent;

  /// サムネイルの縦横比。ショートとリールは縦長、動画は横長、X の画像は横長、Instagram は正方形。
  double get thumbnailAspectRatio => switch ((source, kind)) {
    (SnsService.youtube, PostKind.short) => 9 / 16,
    (SnsService.instagram, PostKind.reel) => 9 / 16,
    (SnsService.youtube, _) => 16 / 9,
    (SnsService.x, _) => 16 / 9,
    _ => 1,
  };

  /// 動画本体（[videoUrl]）をアプリで再生する動画。Instagram の動画（リール・動画）と X の動画（GIF を含む）。
  bool get isFileVideo => switch (source) {
    SnsService.instagram => kind == PostKind.reel || kind == PostKind.video,
    SnsService.x => kind == PostKind.video,
    _ => false,
  };

  /// 横に送って見るカルーセル（中身が2枚以上）。
  bool get isCarousel => media.length > 1;

  /// カルーセルの [index] 枚目を、1件の投稿として表す（画像・動画の表示を投稿と共通にする）。
  Post mediaAt(int index) {
    final m = media[index];
    return Post(
      id: '$id#$index',
      creatorId: creatorId,
      source: source,
      kind: m.isVideo ? PostKind.video : PostKind.image,
      text: text,
      postedAt: postedAt,
      permalink: permalink,
      thumbnailUrl: m.imageUrl,
      videoUrl: m.videoUrl,
    );
  }

  /// YouTube の動画 ID（`id` が `yt:{動画 ID}`）。YouTube の投稿でなければ null。
  String? get youtubeVideoId {
    if (source != SnsService.youtube || !id.startsWith('yt:')) return null;
    final videoId = id.substring(3);
    return videoId.isEmpty ? null : videoId;
  }
}

/// カルーセルの1枚。`posts.media` の1件。
class PostMedia {
  const PostMedia({required this.isVideo, this.imageUrl, this.videoUrl});

  factory PostMedia.fromJson(Map<String, dynamic> json) => PostMedia(
    isVideo: json['type'] == 'video',
    imageUrl: json['image_url'] as String?,
    videoUrl: json['video_url'] as String?,
  );

  final bool isVideo;

  /// 画像。動画はサムネイル。
  final String? imageUrl;

  /// 動画本体の URL。動画だけ。Instagram が返さない動画は空。
  final String? videoUrl;
}

/// 新しい順に並べる。
List<Post> sortNewestFirst(Iterable<Post> posts) =>
    posts.toList()..sort(compareNewestFirst);

/// 新しい順に並べる比較。同じ時刻なら ID の降順（サーバーの並びにそろえ、読み直しで入れ替わらないようにする）。
int compareNewestFirst(Post a, Post b) {
  final byTime = b.postedAt.compareTo(a.postedAt);
  return byTime != 0 ? byTime : b.id.compareTo(a.id);
}
