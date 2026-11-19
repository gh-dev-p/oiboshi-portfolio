import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'l10n_labels.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/post.dart';
import '../../../domain/models/sns_service.dart';
import '../../../utils/formatters.dart';
import '../../../utils/open_url.dart';
import '../themes/app_colors.dart';
import 'link_text.dart';
import 'oshi_avatar.dart';
import 'sns_style.dart';
import 'one_line_text.dart';

/// タイムラインの投稿。SNS を問わず、同じ枠（投稿者の行、本文、画像、数）で出す（画面定義書 2.2.1）。
/// SNS はスケジュールと同じプラットフォームのアイコンで見分け、画像の縦横比は SNS に合わせる。
/// 投稿者の行を押すと [onAuthorTap]、ほかを押すと [onTap]。
/// X の投稿も同じ枠・同じ並びで出し、X の表示の決まりで外せないもの（右上の X の投稿者と X のロゴ、時間の隣の「Xで見る」）を足す。
/// いいね数・コメント数は出さない。
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.author,
    required this.now,
    required this.onTap,
    this.onAuthorTap,
  });

  final Post post;
  final Creator author;
  final DateTime now;
  final VoidCallback onTap;

  /// 投稿者の行を押したとき。null なら、そこも [onTap]。
  final VoidCallback? onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = post.text.isEmpty && post.source == SnsService.youtube
        ? AppLocalizations.of(context)!.postKind(post.kind)
        : post.text;
    final countStyle = TextStyle(
      fontSize: 13,
      height: 18 / 13,
      color: c.textMuted,
    );
    final isX = post.source == SnsService.x;
    final counts = [
      // いいね数・コメント数は Instagram だけ。いいね数が隠されていれば、アイコンだけ出す。
      // X は、押せないいいね・返信のアイコンを出せないので、出さない（代わりに「Xで見る」）。
      if (post.source == SnsService.instagram) ...[
        _Count(
          icon: Icons.favorite_border,
          iconColor: c.textMuted,
          count: post.likeCount,
          style: countStyle,
        ),
        if (post.commentCount != null)
          _Count(
            icon: Icons.chat_bubble_outline,
            iconColor: c.textMuted,
            count: post.commentCount,
            style: countStyle,
          ),
      ],
      // 再生回数は YouTube だけ（X の表示回数は出さない）。
      if (post.source == SnsService.youtube && post.viewCount != null)
        _Count(
          icon: Icons.visibility_outlined,
          iconColor: c.textMuted,
          count: post.viewCount,
          style: countStyle,
        ),
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorRow(
              post: post,
              author: author,
              now: now,
              onTap: onAuthorTap,
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 8),
              LinkText(
                text,
                fallbackUrl: Uri.tryParse(post.permalink),
                xEntities: isX,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  height: 22 / 15,
                  color: c.textPrimary,
                ),
              ),
            ],
            if (post.thumbnailUrl != null || post.isFileVideo) ...[
              const SizedBox(height: 10),
              _PostMedia(post: post),
            ],
            if (counts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (var i = 0; i < counts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 24),
                    counts[i],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 投稿者の行。アイコン、名前、プラットフォームのアイコン、投稿からの時間。
/// X の投稿は、名前の下に時間と「Xで見る」を出し、プラットフォームのアイコンの代わりに、右上に [XAuthorLine] を出す。
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({
    required this.post,
    required this.author,
    required this.now,
    required this.onTap,
  });

  final Post post;
  final Creator author;
  final DateTime now;

  /// 押したとき。null なら、押しても投稿を押したことになる。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isX = post.source == SnsService.x;
    final name = OneLineText(
      author.name,
      style: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w700,
        color: c.textPrimary,
      ),
    );
    // 時間（X は「Xで見る」も）を押すと、元の投稿を開く。
    final time = PostTimeLink(
      post: post,
      text: relativeTime(
        post.postedAt,
        now: now,
        l10n: AppLocalizations.of(context)!,
      ),
      style: TextStyle(fontSize: 12, height: 16 / 12, color: c.textMuted),
      strongColor: c.textPrimary,
    );
    final row = Row(
      mainAxisSize: isX ? MainAxisSize.min : MainAxisSize.max,
      children: [
        AvatarImage(url: author.avatarUrl, size: 36),
        const SizedBox(width: 10),
        // X は、右上に X の投稿者を2段で出すので、時間（と「Xで見る」）を名前の下に出す。
        if (isX)
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [name, time],
            ),
          )
        else ...[
          Flexible(child: name),
          const SizedBox(width: 8),
          PlatformIcon(post.source, size: 18),
          const SizedBox(width: 8),
          time,
        ],
      ],
    );
    final leading = onTap == null
        ? row
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: row,
          );
    if (!isX) return leading;
    return WithXAuthorLine(leading: leading, author: author);
  }
}

/// 投稿からの時間。X の投稿は、隣に「Xで見る」を出す（X の表示の決まり）。押すと、元の投稿を開く。
/// [text] は、時間を含む、出す文字（「{種類} ・ {時間}」など）。「Xで見る」は [strongColor] の太字。
class PostTimeLink extends StatelessWidget {
  const PostTimeLink({
    super.key,
    required this.post,
    required this.text,
    required this.style,
    required this.strongColor,
  });

  final Post post;
  final String text;
  final TextStyle style;
  final Color strongColor;

  @override
  Widget build(BuildContext context) {
    final isX = post.source == SnsService.x;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openPermalink(post),
      child: isX
          ? OneLineText.rich(
              TextSpan(
                children: [
                  TextSpan(text: text),
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: AppLocalizations.of(context)!.commonViewOnX,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: strongColor,
                    ),
                  ),
                ],
              ),
              style: style,
            )
          : OneLineText(text, style: style),
    );
  }
}

/// 元の投稿を開く。その SNS のアプリがあれば、アプリで開く。
void openPermalink(Post post) {
  final url = Uri.tryParse(post.permalink);
  if (url != null) openUrl(url);
}

/// [leading] の右端（投稿の右上）に、[XAuthorLine] を並べる。
/// X の投稿者の表示名・@ユーザー名は、アイコンの幅の2倍までで、入りきらないときは「…」で切る。
class WithXAuthorLine extends StatelessWidget {
  const WithXAuthorLine({
    super.key,
    required this.leading,
    required this.author,
    this.onDark = false,
  });

  final Widget leading;
  final Creator? author;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: leading),
        const SizedBox(width: 8),
        XAuthorLine(author: author, onDark: onDark),
      ],
    );
  }
}

/// X の投稿の、右上に出す投稿者（X の表示の決まり。tech-risks.md 2.21、画面定義書 2.2.1）。
/// 左から、2段（1段目：表示名／2段目：@ユーザー名）、X でのアイコン、X のロゴ（右の端）。
/// アイコンは X のロゴと同じ大きさで、2段の文字と同じ高さ（文字がアイコン・ロゴの高さからはみ出さない）。
/// 2段は灰色の小さい字で、左をそろえる。
/// アイコン・表示名・@ユーザー名を押すと、X のプロフィールを開く。
/// 追星の発信者のものではなく、X のものを出す。X のプロフィールをまだ取れていなければ、
/// 表示名の代わりに @ユーザー名を1段目に出し、アイコンは仮の人の形にする。
/// 2段の文字の欄は、アイコンの幅の2倍（[textMaxWidth]）までで、入りきらないときは、
/// 表示名と @ユーザー名の右を「…」で切る。
/// [onDark] は、投稿ビューアのような暗い背景の上に出すとき。
class XAuthorLine extends StatelessWidget {
  const XAuthorLine({super.key, required this.author, this.onDark = false});

  /// 2段の文字の大きさと、1段の高さ。
  static const double fontSize = 10;
  static const double lineHeight = 11;

  /// アイコンと X のロゴの大きさ。2段の文字の高さにそろえる。
  static const double iconSize = lineHeight * 2;

  /// 2段の文字の欄の幅の上限。アイコンの幅の2倍。
  static const double textMaxWidth = iconSize * 2;

  final Creator? author;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final account = author?.linkedAccounts[SnsService.x];
    final username = account?.profileUsername ?? account?.account;
    final name = account?.profileName ?? (username == null ? '' : '@$username');
    final profile = username == null ? null : Uri.https('x.com', '/$username');
    final muted = onDark ? Colors.white.withValues(alpha: 0.7) : c.textMuted;
    final style = TextStyle(
      fontSize: fontSize,
      height: lineHeight / fontSize,
      color: muted,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: profile == null ? null : () => openUrl(profile),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: textMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OneLineText(name, style: style),
                        if (username != null && account?.profileName != null)
                          OneLineText('@$username', style: style),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                AvatarImage(url: account?.profileImageUrl, size: iconSize),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 暗い背景の上でないときは、画面の明るさに従う（ダークモードで白のロゴにする）。
        PlatformIcon(
          SnsService.x,
          size: iconSize,
          onDark: onDark ? true : null,
        ),
      ],
    );
  }
}

/// 投稿の画像。縦横比は SNS に合わせる。ショートは縦長なので、小さめに出す。
class _PostMedia extends StatelessWidget {
  const _PostMedia({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final (aspectRatio, width) = switch ((post.source, post.kind)) {
      (SnsService.youtube, PostKind.short) => (9 / 16, 160.0),
      (SnsService.instagram, PostKind.reel) => (4 / 5, null),
      (SnsService.instagram, _) => (1.0, null),
      _ => (16 / 9, null),
    };
    return Stack(
      children: [
        PostThumbnail(
          url: post.thumbnailUrl,
          aspectRatio: aspectRatio,
          radius: 12,
          width: width,
          iconSize: 28,
        ),
        // Instagram と X の動画は、右上に動画のマークを出す。
        if (post.isFileVideo)
          const Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.movie_outlined,
              size: 22,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
            ),
          ),
      ],
    );
  }
}

/// 投稿のサムネイル。なければ、灰色の面にアイコン。
class PostThumbnail extends StatelessWidget {
  const PostThumbnail({
    super.key,
    required this.url,
    required this.aspectRatio,
    this.radius = 0,
    this.iconSize = 40,
    this.width,
  });

  final String? url;
  final double aspectRatio;
  final double radius;
  final double iconSize;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final placeholder = ColoredBox(
      color: c.surfaceVariant,
      child: Center(
        child: Icon(Icons.image_outlined, size: iconSize, color: c.placeholder),
      ),
    );
    final url = this.url;
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: url == null || url.isEmpty
              ? placeholder
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                  // 最初の絵が届くまでは、灰色の面を出す（loadingBuilder は、読み込みが始まる前は空になる）。
                  frameBuilder: (_, child, frame, sync) =>
                      frame == null && !sync ? placeholder : child,
                ),
        ),
      ),
    );
  }
}

/// アイコンと数の組（いいね数・コメント数）。数が空（投稿者が隠している）なら、アイコンだけ出す。
class _Count extends StatelessWidget {
  const _Count({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.style,
  });

  final IconData icon;
  final Color iconColor;
  final int? count;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final count = this.count;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            compactCount(count, AppLocalizations.of(context)!),
            style: style,
          ),
        ],
      ],
    );
  }
}

/// 投稿のまとめなどで使う、コンパクトな投稿の行。
class CompactPostRow extends StatelessWidget {
  const CompactPostRow({
    super.key,
    required this.post,
    required this.now,
    required this.onTap,
    this.showChevron = false,
    this.metaStyle = CompactPostMeta.kindAndRelative,
    this.author,
  });

  final Post post;
  final DateTime now;
  final VoidCallback onTap;

  /// 投稿者。X の投稿は、X の表示の決まりに合わせて、右上に X の投稿者（[XAuthorLine]）を出す。
  final Creator? author;
  final bool showChevron;
  final CompactPostMeta metaStyle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final meta = switch (metaStyle) {
      CompactPostMeta.kindAndRelative => l10n.commonPostKindTime(
        l10n.postKind(post.kind),
        relativeTime(post.postedAt, now: now, l10n: l10n),
      ),
      CompactPostMeta.sourceAndClock => l10n.commonServiceTime(
        l10n.sns(post.source),
        clockTime(post.postedAt),
      ),
    };
    final thumb = post.thumbnailUrl;
    final (thumbW, thumbH) = switch ((post.source, post.kind)) {
      (SnsService.youtube, PostKind.short) => (54.0, 96.0),
      (SnsService.youtube, _) => (96.0, 54.0),
      (SnsService.instagram, _) => (64.0, 64.0),
      _ => (0.0, 0.0),
    };
    final isX = post.source == SnsService.x;
    final metaTextStyle = TextStyle(
      fontSize: 11,
      height: 16 / 11,
      color: c.textMuted,
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isX)
                    // X は、バッジの代わりに、右上に X の投稿者を出し、時間の隣に「Xで見る」を出す。
                    WithXAuthorLine(
                      author: author,
                      leading: PostTimeLink(
                        post: post,
                        text: meta,
                        style: metaTextStyle,
                        strongColor: c.textPrimary,
                      ),
                    )
                  else
                    Row(
                      children: [
                        SourceBadge(post.source),
                        const SizedBox(width: 6),
                        Text(meta, style: metaTextStyle),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text(
                    post.text.isEmpty ? l10n.postKind(post.kind) : post.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (thumbW > 0 &&
                (thumb != null || post.source != SnsService.x)) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: thumbW,
                height: thumbH,
                child: PostThumbnail(
                  url: thumb,
                  aspectRatio: thumbW / thumbH,
                  radius: 6,
                  iconSize: 22,
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 22, color: c.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

enum CompactPostMeta { kindAndRelative, sourceAndClock }
