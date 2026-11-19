import 'package:flutter/material.dart';

import '../../../domain/models/oshi.dart';
import '../themes/app_colors.dart';

/// アイコンの下に重ねる印。
enum OshiBadge {
  live,
  newPost;

  /// 推しの状態（[OshiRing]）の印。配信中は「LIVE」、新着ありは「NEW」、既読は印なし（null）。
  /// ホームの推しレーンと推しリストで使う。
  static OshiBadge? fromRing(OshiRing ring) => switch (ring) {
    OshiRing.live => OshiBadge.live,
    OshiRing.hasNew => OshiBadge.newPost,
    OshiRing.read => null,
  };
}

/// 推しのアイコン。リングで状態（配信中・新着あり・既読）を表す。
/// [ring] が null なら、リングなしの丸いアイコン。
/// [badge] を渡すと、リングにかかわらず、その印を下に出す（ホームの推しレーン）。
class OshiAvatar extends StatelessWidget {
  const OshiAvatar({
    super.key,
    required this.avatarUrl,
    required this.size,
    this.ring,
    this.showLiveLabel = true,
    this.badge,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String? avatarUrl;

  /// リングを含む外径。
  final double size;
  final OshiRing? ring;

  /// 配信中のとき、下に「LIVE」の印を出す。
  final bool showLiveLabel;

  /// 下に出す印。null なら、配信中のとき（[showLiveLabel] が真なら）「LIVE」を出す。
  final OshiBadge? badge;

  /// リングの代わりに、単色の枠を描く（カバーの上のアイコンなど）。
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ringWidth = switch (ring) {
      OshiRing.live || OshiRing.hasNew => 3.0,
      OshiRing.read => 1.5,
      null => borderWidth,
    };
    // 写真はリングの内側に少し余白を置く（Figma：72 のとき 6、60・48 のとき 5）。
    final inset = ring == null ? ringWidth : (size >= 72 ? 6.0 : 5.0);
    final inner = size - inset * 2;
    final decoration = switch (ring) {
      OshiRing.live => BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.live, c.livePink],
        ),
      ),
      // 新着の輪は、紺・緑・青（赤は配信中の輪と取り違えるので使わない）。
      OshiRing.hasNew => BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.accentNavy, c.accentGreen, c.accentBlue],
        ),
      ),
      OshiRing.read => BoxDecoration(
        shape: BoxShape.circle,
        color: c.unselected,
      ),
      null => BoxDecoration(shape: BoxShape.circle, color: borderColor),
    };
    final avatar = Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      child: Container(
        width: size - ringWidth * 2,
        height: size - ringWidth * 2,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.background),
        alignment: Alignment.center,
        child: AvatarImage(url: avatarUrl, size: inner),
      ),
    );
    final badge =
        this.badge ??
        (ring == OshiRing.live && showLiveLabel ? OshiBadge.live : null);
    if (badge == null) return avatar;
    final fontSize = size >= 56 ? 9.0 : 8.0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        avatar,
        Positioned(
          bottom: -8,
          child: switch (badge) {
            OshiBadge.live => _LiveLabel(fontSize: fontSize),
            OshiBadge.newPost => _NewLabel(fontSize: fontSize),
          },
        ),
      ],
    );
  }
}

/// 丸いアイコン画像。なければ、人型のプレースホルダー。
class AvatarImage extends StatelessWidget {
  const AvatarImage({super.key, required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.avatarFill),
      child: Icon(Icons.person, size: size * 0.55, color: c.placeholder),
    );
    final url = this.url;
    if (url == null || url.isEmpty) return placeholder;
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

/// 「LIVE」の印（グラデーションの小さな角丸）。
class _LiveLabel extends StatelessWidget {
  const _LiveLabel({this.fontSize = 9});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _AvatarLabel(
      text: 'LIVE',
      colors: [c.live, c.livePink],
      fontSize: fontSize,
    );
  }
}

/// 「NEW」の印（新着あり。ホームの推しレーン）。
class _NewLabel extends StatelessWidget {
  const _NewLabel({this.fontSize = 9});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _AvatarLabel(
      text: 'NEW',
      colors: [c.accentNavy, c.accentNavy],
      textColor: c.onAccent,
      fontSize: fontSize,
    );
  }
}

class _AvatarLabel extends StatelessWidget {
  const _AvatarLabel({
    required this.text,
    required this.colors,
    required this.fontSize,
    this.textColor = Colors.white,
  });

  final String text;
  final List<Color> colors;
  final double fontSize;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.background, width: 2),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.4,
        ),
      ),
    );
  }
}
