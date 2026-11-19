import 'package:flutter/material.dart';

/// 投稿ビューアの画像・動画ファイルを、拡大して見られるようにする（画面定義書 2.5.1）。
/// 2本の指で広げる・縮める。ダブルタップで拡大し、もう一度ダブルタップで元に戻す。
/// 拡大している間は、1本の指で動かして見られる（元の大きさでは、1本の指の動きは投稿・画像の送りに渡す）。
/// 拡大しているかは [zoomed] で知らせ、ビューアは、その間、投稿・画像を送らない。
/// 表示中でなくなったら（[active] が false）、元の大きさに戻す。
class ZoomableMedia extends StatefulWidget {
  const ZoomableMedia({
    super.key,
    required this.active,
    required this.zoomed,
    required this.child,
  });

  /// 拡大の上限。
  static const double maxScale = 4;

  /// ダブルタップで拡大するときの倍率。
  static const double doubleTapScale = 2.5;

  /// 表示中か。表示中でなくなったら、元の大きさに戻す。
  final bool active;

  /// 拡大しているか。表示中のものだけが書き込む。
  final ValueNotifier<bool> zoomed;
  final Widget child;

  @override
  State<ZoomableMedia> createState() => _ZoomableMediaState();
}

class _ZoomableMediaState extends State<ZoomableMedia>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(_onAnimate);
  Animation<Matrix4>? _tween;

  /// ダブルタップした所。そこを中心に拡大する。
  Offset _doubleTapAt = Offset.zero;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  @override
  void didUpdateWidget(ZoomableMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) _reset();
  }

  @override
  void dispose() {
    // 拡大したまま消えるのは、ビューアを閉じたときだけ（拡大の間は送らないため）。ビューアの値は戻さない。
    _animation.dispose();
    _transform.dispose();
    super.dispose();
  }

  double get _scale => _transform.value.getMaxScaleOnAxis();

  void _onTransform() {
    final zoomed = _scale > 1.01;
    if (zoomed == _isZoomed) return;
    setState(() => _isZoomed = zoomed);
    if (widget.active) widget.zoomed.value = zoomed;
  }

  void _onAnimate() {
    final tween = _tween;
    if (tween != null) _transform.value = tween.value;
  }

  void _animateTo(Matrix4 target) {
    _tween = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: _animation, curve: Curves.easeOutCubic));
    _animation.forward(from: 0);
  }

  /// 元の大きさに、すぐ戻す。
  void _reset() {
    _animation.stop();
    _transform.value = Matrix4.identity();
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    const s = ZoomableMedia.doubleTapScale;
    final p = _doubleTapAt;
    // ダブルタップした所が、拡大したあとも同じ所に来るようにする。
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(-p.dx * (s - 1), -p.dy * (s - 1), 0, 1)
        ..scaleByDouble(s, s, 1, 1),
    );
  }

  /// 指を離したときに、ほぼ元の大きさなら、ぴったり戻す。
  void _onInteractionEnd(ScaleEndDetails _) {
    if (_scale <= 1.01) _animateTo(Matrix4.identity());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: ZoomableMedia.maxScale,
        // 元の大きさでは、1本の指の動きを、投稿・画像の送りに渡す。
        panEnabled: _isZoomed,
        onInteractionStart: (_) => _animation.stop(),
        onInteractionEnd: _onInteractionEnd,
        child: widget.child,
      ),
    );
  }
}
