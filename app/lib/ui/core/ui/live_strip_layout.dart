import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/open_url.dart';
import 'page_dots.dart';
import 'sns_style.dart';

/// 配信の帯（配信ビューアの映像の下）の並びの決まり（画面定義書（ファン）2.2.1・2.4.3）。
/// 初期位置モード（埋め込みビューア）と固定ビューアは、どちらも [regular] を使う。
class LiveStripMetrics {
  const LiveStripMetrics._({
    required this.size,
    required this.gap,
    required this.edge,
  });

  /// 初期位置モード（埋め込みビューア）・固定ビューア。
  static const regular = LiveStripMetrics._(size: 22, gap: 12, edge: 12);

  /// 「LIVE」と配信元の印（[LiveSourceBadge]）の高さと、アイコンの大きさ。
  final double size;

  /// となり合う印・アイコンの、見た目の間。
  final double gap;

  /// 帯の左右の端から、いちばん外の印・アイコンの見た目までの余白。
  final double edge;

  /// 押せる範囲の幅。見た目の左右に、[gap] の半分ずつを足す。
  double get itemWidth => size + gap;
}

/// 帯の並び。左の組を左端、右の組を右端に置き、真ん中の組（矢印と点）を帯の真ん中に置く。
/// 真ん中の組が左右の組に重なるときだけ、重ならないところまでずらす（それでも入らなければ縮める）。
class LiveStripLayout extends StatelessWidget {
  const LiveStripLayout({
    super.key,
    required this.metrics,
    required this.height,
    required this.foreground,
    required this.leading,
    this.center,
    required this.trailing,
  });

  final LiveStripMetrics metrics;
  final double height;

  /// アイコンの色。
  final Color foreground;
  final Widget leading;
  final Widget? center;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final center = this.center;
    return SizedBox(
      height: height,
      child: Padding(
        // 外側のアイコンの押せる範囲は、見た目の外に [gap] の半分を持つので、そのぶん余白を減らす。
        padding: EdgeInsets.symmetric(
          horizontal: metrics.edge - metrics.gap / 2,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: metrics.size),
          child: CustomMultiChildLayout(
            delegate: _StripDelegate(),
            children: [
              LayoutId(id: _Slot.leading, child: leading),
              if (center != null)
                LayoutId(
                  id: _Slot.center,
                  child: FittedBox(fit: BoxFit.scaleDown, child: center),
                ),
              LayoutId(
                id: _Slot.trailing,
                child: Row(mainAxisSize: MainAxisSize.min, children: trailing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Slot { leading, center, trailing }

class _StripDelegate extends MultiChildLayoutDelegate {
  @override
  void performLayout(Size size) {
    BoxConstraints within(double width) =>
        BoxConstraints(maxWidth: math.max(0, width), maxHeight: size.height);
    final trailing = layoutChild(_Slot.trailing, within(size.width));
    final leading = layoutChild(
      _Slot.leading,
      within(size.width - trailing.width),
    );
    positionChild(_Slot.leading, Offset(0, (size.height - leading.height) / 2));
    positionChild(
      _Slot.trailing,
      Offset(size.width - trailing.width, (size.height - trailing.height) / 2),
    );
    if (hasChild(_Slot.center)) {
      final room = size.width - leading.width - trailing.width;
      final center = layoutChild(_Slot.center, within(room));
      final x = ((size.width - center.width) / 2)
          .clamp(
            leading.width,
            math.max(leading.width, size.width - trailing.width - center.width),
          )
          .toDouble();
      positionChild(_Slot.center, Offset(x, (size.height - center.height) / 2));
    }
  }

  @override
  bool shouldRelayout(_StripDelegate oldDelegate) => false;
}

/// 帯のアイコンのボタン。幅は [LiveStripMetrics.itemWidth]、高さは帯いっぱい。
// IconButton は、押せる範囲を 48 に広げるので、帯に収まるよう、大きさを決めて作る。
class LiveStripButton extends StatelessWidget {
  const LiveStripButton({
    super.key,
    required this.metrics,
    required this.height,
    required this.tooltip,
    required this.onPressed,
    required this.child,
  });

  final LiveStripMetrics metrics;
  final double height;
  final String tooltip;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkResponse(
      onTap: onPressed,
      radius: metrics.itemWidth / 2 + 2,
      child: SizedBox(
        width: metrics.itemWidth,
        height: height,
        child: Center(child: child),
      ),
    ),
  );
}

/// 「LIVE」と配信元のロゴを1つにした印（tech-risks.md 2.23）。配信元の色の背景に、単色のロゴ（[PlatformMark]）と「LIVE」を出す。
/// 押すと、配信元を開く（YouTube・Twitch の規約：配信元を示し、配信元へ辿れるようにする。2.22）。
/// ロゴの周りには、各社の余白（YouTube は三角の大きさ、Twitch は目の幅）より広く空ける。
class LiveSourceBadge extends StatelessWidget {
  const LiveSourceBadge({
    super.key,
    required this.metrics,
    required this.service,
    required this.tooltip,
    required this.onPressed,
  });

  final LiveStripMetrics metrics;
  final SnsService service;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // YouTube のアイコンは横長なので、ほかより低くして、見た目の大きさをそろえる。
    final markHeight = switch (service) {
      SnsService.youtube => 10.0,
      _ => 12.0,
    };
    final radius = BorderRadius.circular(4);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.gap / 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: SnsStyle.color(service),
          borderRadius: radius,
          child: InkWell(
            onTap: onPressed,
            borderRadius: radius,
            child: Container(
              height: metrics.size,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlatformMark(service, height: markHeight),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 配信元で、その配信を開く（YouTube・Twitch の規約：配信元へ辿れるようにする。tech-risks.md 2.22）。
/// 帯の「LIVE」と配信元の印（[LiveSourceBadge]）を押したときに使う。
Future<bool> openLiveSource(Live live) => openUrl(Uri.parse(live.link));

/// 帯の真ん中の組。前後の矢印と、何人目かの点（[position] があるとき）。
class LiveStripStepper extends StatelessWidget {
  const LiveStripStepper({
    super.key,
    required this.metrics,
    required this.height,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.onStep,
    this.position,
    this.dotsColor = Colors.white,
  });

  final LiveStripMetrics metrics;
  final double height;
  final String previousTooltip;
  final String nextTooltip;

  /// 矢印を押したとき（-1 なら前、1 なら次）。
  final void Function(int step) onStep;

  /// 何人目か（矢印の間の点）。null なら、点を出さない。
  final ({int index, int count})? position;

  /// いまの点の色（[PageDots.color]）。
  final Color dotsColor;

  @override
  Widget build(BuildContext context) {
    final position = this.position;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LiveStripButton(
          metrics: metrics,
          height: height,
          tooltip: previousTooltip,
          onPressed: () => onStep(-1),
          child: const Icon(Icons.chevron_left),
        ),
        if (position != null)
          PageDots(
            count: position.count,
            index: position.index,
            color: dotsColor,
          ),
        LiveStripButton(
          metrics: metrics,
          height: height,
          tooltip: nextTooltip,
          onPressed: () => onStep(1),
          child: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

/// 帯の右端の、固定ビューアのボタン（下部ナビのスイッチと同じ、再生の画面の形の線のアイコン）。
/// 押すと、その配信を固定ビューアで流す。
class LiveStripPinButton extends StatelessWidget {
  const LiveStripPinButton({
    super.key,
    required this.metrics,
    required this.height,
    required this.onPressed,
  });

  final LiveStripMetrics metrics;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => LiveStripButton(
    metrics: metrics,
    height: height,
    tooltip: AppLocalizations.of(context)!.commonLivePin,
    onPressed: onPressed,
    child: const Icon(Icons.smart_display_outlined),
  );
}
