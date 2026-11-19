import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/config/app_flavor.dart';

void main() {
  group('flavorMismatch（環境構成 10）', () {
    const devUrl = 'https://devref.supabase.co';

    test('prod のアプリは本番につなげる', () {
      expect(flavorMismatch(AppFlavor.prod, prodSupabaseUrl), isNull);
    });

    test('prod のアプリが本番以外につなごうとしたら止める', () {
      expect(flavorMismatch(AppFlavor.prod, devUrl), isNotNull);
      expect(flavorMismatch(AppFlavor.prod, ''), isNotNull);
    });

    test('dev のアプリは dev とローカルにつなげる', () {
      expect(flavorMismatch(AppFlavor.dev, devUrl), isNull);
      expect(flavorMismatch(AppFlavor.dev, 'http://127.0.0.1:54321'), isNull);
    });

    test('dev のアプリが本番につなごうとしたら止める', () {
      expect(flavorMismatch(AppFlavor.dev, prodSupabaseUrl), isNotNull);
    });
  });
}
