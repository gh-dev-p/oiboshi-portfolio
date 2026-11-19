import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/ui/qr_code_view.dart';

const _link = 'https://oiboshi.perrii.app/c/minato';

/// [data] の QR を [side] の正方形に描いて、画素を読む。
Future<ByteData> _render(String data, int side) async {
  final recorder = ui.PictureRecorder();
  paintQrCode(
    Canvas(recorder),
    Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
    data,
    color: Colors.black,
    background: Colors.white,
  );
  final image = await recorder.endRecording().toImage(side, side);
  return (await image.toByteData())!;
}

bool _isDark(ByteData bytes, int side, int x, int y) =>
    bytes.getUint8((y * side + x) * 4) < 128;

void main() {
  test('共有のリンクの QR を作る（同じ中身なら同じ形）', () {
    final a = qrImageFor(_link);
    final b = qrImageFor(_link);
    expect(a.moduleCount, greaterThanOrEqualTo(21));
    for (var r = 0; r < a.moduleCount; r++) {
      for (var c = 0; c < a.moduleCount; c++) {
        expect(a.isDark(r, c), b.isDark(r, c));
      }
    }
    // 左上の位置検出の模様（7×7 の外枠は暗い）。
    for (var i = 0; i < 7; i++) {
      expect(a.isDark(0, i), isTrue);
      expect(a.isDark(i, 0), isTrue);
    }
  });

  test('余白を空けて描く（四隅は背景、位置検出の模様は暗い）', () async {
    final image = qrImageFor(_link);
    final modules = image.moduleCount + qrQuietZoneModules * 2;
    final side = modules * 4;
    final bytes = await _render(_link, side);
    expect(_isDark(bytes, side, 1, 1), isFalse, reason: '余白');
    expect(_isDark(bytes, side, side - 2, side - 2), isFalse, reason: '余白');
    // 余白のすぐ内側（左上の位置検出の模様の角）。
    final inner = qrQuietZoneModules * 4 + 1;
    expect(_isDark(bytes, side, inner, inner), isTrue);
  });

  testWidgets('画面に出す', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: QrCodeView(
            data: _link,
            size: 160,
            color: Colors.black,
            background: Colors.white,
            semanticLabel: 'QR',
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(CustomPaint).last), const Size(160, 160));
    expect(find.bySemanticsLabel('QR'), findsOneWidget);
  });
}
