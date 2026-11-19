import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/domain/models/schedule_layout.dart';

ColumnItem block(double top, double bottom) =>
    ColumnItem(top: top, bottom: bottom, isChip: false);
ColumnItem chip(double top, double bottom) =>
    ColumnItem(top: top, bottom: bottom, isChip: true);

void main() {
  const usable = 100.0;

  test('ほかと重ならない要素は、ブロックもチップも幅いっぱい', () {
    final slots = layoutColumn([
      block(0, 50),
      chip(60, 86),
      chip(200, 230),
    ], usable);
    for (final s in slots) {
      expect(s, (left: 0.0, width: usable));
    }
  });

  test('ブロックとチップが画面の上で重なれば、ブロックを左半分、チップを右半分に出す', () {
    // チップの時刻はブロックの後でも、チップの高さぶんで重なる。
    final slots = layoutColumn([block(0, 50), chip(40, 66)], usable);
    expect(slots[0], (left: 0.0, width: 49.0));
    expect(slots[1], (left: 51.0, width: 49.0));
  });

  test('触れているだけ（端が同じ）なら、重ならない', () {
    final slots = layoutColumn([block(0, 50), chip(50, 76)], usable);
    expect(slots[0].width, usable);
    expect(slots[1].width, usable);
  });

  test('ブロック同士が重なれば、等分する', () {
    final slots = layoutColumn([block(0, 50), block(20, 80)], usable);
    expect(slots[0], (left: 0.0, width: 49.0));
    expect(slots[1], (left: 51.0, width: 49.0));
  });

  test('チップ同士が重なれば横に並べ、重ならないチップは同じ列に戻す', () {
    // A と B が重なり、C は A とは重ならないが B と重なる。列は2つで足りる。
    final slots = layoutColumn([
      chip(0, 26),
      chip(10, 36),
      chip(30, 56),
    ], usable);
    expect(slots[0], (left: 0.0, width: 49.0));
    expect(slots[1], (left: 51.0, width: 49.0));
    expect(slots[2], (left: 0.0, width: 49.0));
  });
}
