import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/ui/viewer_control.dart';

/// 下部ナビのコントローラーの、はじいた向きの決め方（機能仕様書 4.3.5）。
void main() {
  ViewerControl? of(double dx, double dy) =>
      ViewerControlDirection.of(Offset(dx, dy));

  test('決まる距離（36pt）に届かなければ、決めない', () {
    expect(of(0, -35), isNull);
    expect(of(20, -20), isNull);
    expect(of(0, -36), ViewerControl.playPause);
  });

  test('上・上右・上左・右・左に分け、下は使わない', () {
    expect(of(0, -50), ViewerControl.playPause);
    expect(of(15, -50), ViewerControl.playPause); // 約17°
    expect(of(40, -40), ViewerControl.shuffle); // 45°
    expect(of(-40, -40), ViewerControl.live);
    expect(of(50, 0), ViewerControl.next); // 90°
    expect(of(-50, 0), ViewerControl.previous);
    expect(of(50, 30), ViewerControl.next); // 約121°（少し下向きでも横）
    expect(of(0, 50), isNull); // 下
    expect(of(30, 50), isNull); // 約149°
  });

  test('境目：上は 22.5° まで、斜めは 67.5° まで、横は 135° まで', () {
    Offset at(double degrees) {
      final r = degrees * 3.141592653589793 / 180;
      return Offset(50 * math.sin(r), -50 * math.cos(r));
    }

    expect(ViewerControlDirection.of(at(22)), ViewerControl.playPause);
    expect(ViewerControlDirection.of(at(23)), ViewerControl.shuffle);
    expect(ViewerControlDirection.of(at(67)), ViewerControl.shuffle);
    expect(ViewerControlDirection.of(at(68)), ViewerControl.next);
    expect(ViewerControlDirection.of(at(134)), ViewerControl.next);
    expect(ViewerControlDirection.of(at(136)), isNull);
    expect(ViewerControlDirection.of(at(-23)), ViewerControl.live);
    expect(ViewerControlDirection.of(at(-68)), ViewerControl.previous);
  });
}
