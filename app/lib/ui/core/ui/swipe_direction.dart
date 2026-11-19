import 'package:flutter/gestures.dart';

/// 横に払って離したときの向き。速く払ったら、その速さ（[velocity]）。止めてから離したときは、
/// 幅（[width]）の [ratio] より多く動かしていれば、動かした量（[offset]）。どちらでもなければ 0。
/// 正なら右、負なら左。固定ビューア・ホームの配信ビューアの帯と、投稿ビューアと、
/// 下部ナビの固定ビューアのスイッチの引っ張りで使う。
double swipeDirection({
  required double velocity,
  required double offset,
  required double width,
  double minVelocity = kMinFlingVelocity,
  double ratio = 0.25,
}) => velocity.abs() > minVelocity
    ? velocity
    : offset.abs() > width * ratio
    ? offset
    : 0.0;
