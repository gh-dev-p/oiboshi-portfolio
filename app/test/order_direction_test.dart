import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// supabase の Dart の `order()` は、既定が降順（`ascending: false`）。
/// 向きを書き忘れると、並びが逆になる（リンク集・発信者のタイプで起きた）。
/// `lib/` の `order(` には、必ず `ascending:` を書く。
void main() {
  test('order() には、向き（ascending:）を必ず書く', () {
    final missing = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final call = RegExp(r'\.order\(([^()]*)\)');
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final m in call.allMatches(text)) {
        if (!m.group(1)!.contains('ascending:')) {
          final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
          missing.add('${file.path}:$line ${m.group(0)}');
        }
      }
    }
    expect(missing, isEmpty);
  });
}
