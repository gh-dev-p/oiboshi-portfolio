import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 下部ナビのコントローラー（固定ビューアのスイッチ）で、はじいて選ぶ操作（機能仕様書 4.3.5）。
enum ViewerControl {
  /// 上：再生・停止。
  playPause,

  /// 上右：動画シャッフル。
  shuffle,

  /// 上左：配信。
  live,

  /// 右：次の動画・配信。
  next,

  /// 左：前の動画・配信。
  previous,
}

/// はじいた向きの決め方。押した所からの指の動き（[offset]）で決める。
/// 動いた距離が [threshold] に届かなければ、まだ決めない（軽いタップと混ざらないように）。
/// 向きは、真上からの角度で分ける。上は ±22.5°、上右・上左は 22.5〜67.5°、右・左は 67.5〜135°。
/// それより下（下向き）は使わない。
abstract final class ViewerControlDirection {
  /// 操作が決まる距離（pt）。
  static const threshold = 36.0;

  /// 上と斜めの境目（真上からの角度）。
  static const upLimit = 22.5;

  /// 斜めと横の境目。
  static const diagonalLimit = 67.5;

  /// 横と下の境目。下向きは使わない。
  static const sideLimit = 135.0;

  /// [offset] の向きの操作。決まらなければ null。
  static ViewerControl? of(Offset offset) {
    if (offset.distance < threshold) return null;
    // 真上を 0°、右回りを正にする（画面の y は下が正）。
    final degrees = math.atan2(offset.dx, -offset.dy) * 180 / math.pi;
    final angle = degrees.abs();
    final right = degrees > 0;
    if (angle <= upLimit) return ViewerControl.playPause;
    if (angle <= diagonalLimit) {
      return right ? ViewerControl.shuffle : ViewerControl.live;
    }
    if (angle <= sideLimit) {
      return right ? ViewerControl.next : ViewerControl.previous;
    }
    return null;
  }

  /// 触れている間のヒントを置く向き（真上を 0°、右回りを正にした角度）。
  static double angleOf(ViewerControl control) => switch (control) {
    ViewerControl.playPause => 0,
    ViewerControl.shuffle => 45,
    ViewerControl.live => -45,
    ViewerControl.next => 90,
    ViewerControl.previous => -90,
  };
}

/// 動画シャッフルのとき、コントローラーを左右に引っ張ったまま止めて、早送り・巻き戻しする決まり（機能仕様書 4.3.5）。
/// さっと払うと、今までどおり次・前。右・左の向きが決まってから [holdDelay] のあいだ、同じ向きのまま指を離さなければ、
/// 引っ張ったままとみなし、右なら早送り、左なら巻き戻しにする。離すと、そこから再生する（次・前にはしない）。
abstract final class ViewerSeek {
  /// 払うのと、引っ張ったまま止めるのとの境目。右・左の向きが決まってから、この時間そのままなら、早送り・巻き戻し。
  /// 払う指は、向きが決まってからふつう 0.2 秒ほどで離れるので、それより長くする。
  static const holdDelay = Duration(milliseconds: 400);

  /// 再生位置をプレイヤーに送る、いちばん短い間隔（送りすぎて重くならないように間引く）。
  static const sendInterval = Duration(milliseconds: 400);

  /// 前に送った位置へプレイヤーが動き終えるのを待つ、いちばん長い時間。過ぎたら、動き終えなくても次を送る。
  static const maxWait = Duration(milliseconds: 1500);

  /// プレイヤーの位置が、送った位置からこれだけの差に入ったら、動き終えたとみなす。
  static const landedWithin = Duration(seconds: 2);

  /// 速さ（1秒に何秒分動かすか）。同じ向きで引っ張り続けると、1秒ごとに1つ先に進む。最後は最大のまま。
  static const speeds = [5, 10, 20, 40, 60];

  /// 同じ向きで [held] のあいだ引っ張り続けたときの速さ（1秒に何秒分）。
  static int speedAt(Duration held) {
    final step = held.inMilliseconds ~/ 1000;
    return speeds[step < speeds.length ? step : speeds.length - 1];
  }

  /// 終わりの手前で止める余白。終わりまで動かすと、引っ張っている間に次の動画に移ってしまうため。
  /// 離したとき、終わりまでの少しを見られるようにもする。
  static const endMargin = Duration(seconds: 3);

  /// [position] を、動画の頭から、終わりの手前（[duration] − [endMargin]）までに収める。
  static Duration clamp(Duration position, Duration duration) {
    final end = duration - endMargin;
    if (position < Duration.zero) return Duration.zero;
    if (end <= Duration.zero) return Duration.zero;
    return position > end ? end : position;
  }
}

/// コントローラーから固定ビューアへの、早送り・巻き戻しの窓口（[ViewerSeek]）。
/// [start] は、引っ張ったまま止めたときに呼び、始められたら真（偽なら、離したとき今までどおり次・前）。
/// [direction] は、引っ張っている向き（1：右・早送り、-1：左・巻き戻し、0：右左から外れた）。[end] は指を離したとき。
typedef ViewerSeekControl = ({
  bool Function(int direction) start,
  ValueChanged<int> direction,
  VoidCallback end,
});
