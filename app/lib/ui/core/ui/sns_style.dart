import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'l10n_labels.dart';

import '../../../domain/models/creator_link.dart';
import '../../../domain/models/sns_service.dart';

/// プラットフォームの色（Figma）。予定の見分けはプラットフォームの色とアイコンで行う。
abstract final class SnsStyle {
  /// 汎用（プラットフォームのないイベントの公演）。
  static const generic = Color(0xFF5B5BD6);

  /// [dark] なら、暗い画面の色（X は、背景に溶けないよう白にする。X のロゴに合わせる）。
  static Color color(SnsService? service, {bool dark = false}) =>
      switch (service) {
        SnsService.youtube => const Color(0xFFFF0033),
        SnsService.instagram => const Color(0xFFC13584),
        SnsService.twitcasting => const Color(0xFF0098D9),
        SnsService.twitch => const Color(0xFF9146FF),
        SnsService.x =>
          dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
        null => generic,
      };

  /// 画面の明るさに合わせた色（予定表のように、画面の背景の上に塗るとき）。
  static Color colorOf(BuildContext context, SnsService? service) =>
      color(service, dark: Theme.of(context).brightness == Brightness.dark);

  /// 投稿元のバッジ・チップの色。
  static Color badgeColor(SnsService service) => switch (service) {
    SnsService.instagram => const Color(0xFFD62976),
    _ => color(service),
  };
}

/// プラットフォームのアイコン。YouTube・Instagram・ツイキャス・Twitch・X は、各社の公式の素材（`assets/brands/`）を、
/// 形と色を変えずに出す（tech-risks.md 2.21）。プラットフォームのない予定だけ、自前の形。
/// 同じ [size] なら、見た目の大きさがそろう（画面定義書 5.1）。素材は、見えている絵を囲む長方形の面積が、
/// 一辺が [size] の 76% の正方形と同じになるよう、透明の余白を含めて作ってある（X は、線が細く大きく見えるので 66%）。
/// ツイキャス（公式のアプリアイコン「ツイキャス・ライブ」）は、素材に余白がないので、周りに 12% ずつ空けて 76% にする。
class PlatformIcon extends StatelessWidget {
  const PlatformIcon(this.service, {super.key, this.size = 16, this.onDark});

  final SnsService? service;
  final double size;

  /// 暗い背景の上に出すか（X のロゴの白黒を決める）。null なら、画面の明るさに従う。
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final dark = onDark ?? Theme.of(context).brightness == Brightness.dark;
    return switch (service) {
      SnsService.youtube => _logo('youtube.png'),
      SnsService.instagram => _logo('instagram.png'),
      SnsService.twitch => _logo('twitch.png'),
      SnsService.x => _logo(dark ? 'x_white.png' : 'x_black.png'),
      // 一辺を大きさの 76% にする（ほかの素材のロゴと、見た目の大きさをそろえる）。
      SnsService.twitcasting => SizedBox.square(
        dimension: size,
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: Image.asset(
            'assets/brands/twitcasting.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
      null => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: SnsStyle.generic,
          borderRadius: BorderRadius.circular(size * 0.29),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.campaign, size: size * 0.62, color: Colors.white),
      ),
    };
  }

  /// 素材は、余白を含めた正方形（画面定義書 5.1）。
  Widget _logo(String file) => SizedBox.square(
    dimension: size,
    child: Image.asset(
      'assets/brands/$file',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    ),
  );
}

/// 配信元の、背景色の上に置く単色のロゴ（「LIVE」と1つにした印に使う。tech-risks.md 2.23）。
/// YouTube は白の版、Twitch は Black Ops の版、ツイキャスは白抜きの鳥（公式のアプリアイコンの素材）を、形と色を変えずに出す。
/// [height] は、ロゴの絵の高さ（素材は、透明の余白を切り落としてある）。
class PlatformMark extends StatelessWidget {
  const PlatformMark(this.service, {super.key, required this.height});

  final SnsService service;
  final double height;

  @override
  Widget build(BuildContext context) => switch (service) {
    SnsService.youtube => _asset('youtube_white.png'),
    SnsService.twitch => _asset('twitch_black_ops.png'),
    SnsService.twitcasting => _asset('twitcasting_white.png'),
    _ => SizedBox.square(dimension: height),
  };

  Widget _asset(String file) => Image.asset(
    'assets/brands/$file',
    height: height,
    filterQuality: FilterQuality.medium,
  );
}

/// 投稿元のバッジ（「YouTube」「Instagram」「X」）。
class SourceBadge extends StatelessWidget {
  const SourceBadge(this.service, {super.key});

  final SnsService service;

  @override
  Widget build(BuildContext context) {
    final isX = service == SnsService.x;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isX && dark ? Colors.white : SnsStyle.badgeColor(service),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AppLocalizations.of(context)!.sns(service),
        style: TextStyle(
          fontSize: 11,
          height: 14 / 11,
          fontWeight: FontWeight.w700,
          color: isX && dark ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

/// リンクのボタンの左に付ける、行き先のサービスの公式アイコン（届ける・広める仕様書 4.6.7）。
/// 分からない行き先は、ふつうのリンクの印（[color] で塗る）。[web] なら、公開のページで使えるものだけ（[CreatorLinkRules.iconServiceFor]）。
class LinkServiceIcon extends StatelessWidget {
  const LinkServiceIcon({
    super.key,
    required this.url,
    required this.size,
    required this.color,
    this.web = false,
    this.onDark,
  });

  final String url;
  final double size;
  final Color color;
  final bool web;
  final bool? onDark;

  @override
  Widget build(BuildContext context) {
    final service = CreatorLinkRules.iconServiceFor(url, web: web);
    final brand = service == null ? CreatorLinkRules.brandFor(url) : null;
    if (brand != null) {
      // Spotify は円がいっぱいの素材で、見た目の大きさがほかとそろう。決まりの最小（21px）を満たす大きさで使う。
      return SizedBox.square(
        dimension: size,
        child: Image.asset(
          'assets/brands/${brand.asset}',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    if (service == null) {
      return SizedBox.square(
        dimension: size,
        child: Icon(Icons.link, size: size * 0.9, color: color),
      );
    }
    return PlatformIcon(service, size: size, onDark: onDark);
  }
}
