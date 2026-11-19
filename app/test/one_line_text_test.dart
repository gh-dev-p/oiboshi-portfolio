import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/ui/core/ui/one_line_text.dart';

void main() {
  testWidgets('1行の文字は、背の高い文字（絵文字など）が混じっても、行の高さを変えない', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: OneLineText.rich(
            TextSpan(
              children: [
                TextSpan(text: 'しずく'),
                // 絵文字の書体の代わりに、大きな文字を混ぜる（テストの書体には絵文字がない）。
                TextSpan(text: '🐈', style: TextStyle(fontSize: 24)),
              ],
            ),
            style: TextStyle(fontSize: 12, height: 16 / 12),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(OneLineText)).height, 16);
  });

  // 1行の文字に `Text` を使うと、絵文字で行が高くなり、高さを決めた枠からはみ出す（推しレーンの名前で起きた）。
  test('1行の文字は、Text ではなく OneLineText で出す', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('one_line_text.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!RegExp(r'maxLines: 1\b').hasMatch(lines[i])) continue;
        // 幅を測るだけの TextPainter は、出さないので構わない。
        final owner = lines
            .sublist(0, i)
            .lastWhere(
              (l) => RegExp(
                r'(?<![A-Za-z])(Text(\.rich)?|TextPainter)\(',
              ).hasMatch(l),
              orElse: () => '',
            );
        if (!owner.contains('TextPainter(')) {
          offenders.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
