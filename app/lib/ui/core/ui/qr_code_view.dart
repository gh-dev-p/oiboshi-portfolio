import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

/// QR を作る部品（届ける・広める仕様書 4.3.5）。外部のサービスは使わず、端末の中で作る（`qr` パッケージ）。
///
/// 使う場所：「リンクを共有」の画面と、週間の告知画像。
/// 画面に出すときは [QrCodeView]、画像に描くときは [paintQrCode] を使う。見た目（大きさ・色）は使う側が決める。

/// QR の周りに空ける余白（モジュールの数）。読み取りの決まりでは 4。
const qrQuietZoneModules = 4;

/// [data] の QR。誤り訂正は M（15%。ロゴなどを重ねない前提）。
QrImage qrImageFor(String data) => QrImage(
  QrCode(
    payload: QrPayload.fromString(data),
    errorCorrectLevel: QrErrorCorrectLevel.medium,
  ),
);

/// [canvas] の [rect]（正方形にする）に、[data] の QR を描く。[background] を渡すと、余白を含めて塗る。
/// 余白（[qrQuietZoneModules]）は [rect] の内側に取る。
void paintQrCode(
  Canvas canvas,
  Rect rect,
  String data, {
  required Color color,
  Color? background,
}) => _paintQrImage(
  canvas,
  rect,
  qrImageFor(data),
  color: color,
  background: background,
);

void _paintQrImage(
  Canvas canvas,
  Rect rect,
  QrImage image, {
  required Color color,
  Color? background,
}) {
  final side = rect.shortestSide;
  final square = Rect.fromCenter(
    center: rect.center,
    width: side,
    height: side,
  );
  if (background != null) {
    canvas.drawRect(square, Paint()..color = background);
  }
  final count = image.moduleCount;
  final module = side / (count + qrQuietZoneModules * 2);
  final origin = square.topLeft.translate(
    module * qrQuietZoneModules,
    module * qrQuietZoneModules,
  );
  final paint = Paint()
    ..color = color
    ..isAntiAlias = false;
  // 横に続く暗いモジュールを1つの四角にまとめて描く（継ぎ目の線が出ないように）。
  for (var row = 0; row < count; row++) {
    var col = 0;
    while (col < count) {
      if (!image.isDark(row, col)) {
        col++;
        continue;
      }
      final start = col;
      while (col < count && image.isDark(row, col)) {
        col++;
      }
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx + start * module,
          origin.dy + row * module,
          (col - start) * module,
          module,
        ),
        paint,
      );
    }
  }
}

/// [data] の QR を、[size] の正方形で出す。余白を含めて [background] で塗る。
class QrCodeView extends StatelessWidget {
  const QrCodeView({
    super.key,
    required this.data,
    required this.size,
    required this.color,
    required this.background,
    this.semanticLabel,
  });

  final String data;
  final double size;
  final Color color;
  final Color background;

  /// 読み上げの文。null なら読み上げない。
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final painter = CustomPaint(
      size: Size.square(size),
      painter: _QrPainter(data, color: color, background: background),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: painter)
        : Semantics(label: semanticLabel, image: true, child: painter);
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.data, {required this.color, required this.background})
    : image = qrImageFor(data);

  final String data;
  final QrImage image;
  final Color color;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) => _paintQrImage(
    canvas,
    Offset.zero & size,
    image,
    color: color,
    background: background,
  );

  @override
  bool shouldRepaint(_QrPainter old) =>
      old.data != data || old.color != color || old.background != background;
}
