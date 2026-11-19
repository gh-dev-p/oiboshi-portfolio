import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oiboshi/data/services/common/web_auth.dart';

void main() {
  late List<String> opened;
  late int waits;

  setUp(() {
    opened = [];
    waits = 0;
    waitBeforeRetry = (_) async => waits++;
  });

  PlatformException error(String code) => PlatformException(code: code);

  test('土台の画面を取れなかったら、少し待って開き直す（前のブラウザが閉じている途中）', () async {
    var failures = 2;
    openWebAuth = ({required url, required callbackUrlScheme}) async {
      opened.add(url);
      if (failures-- > 0) throw error('ACQUIRE_ROOT_VIEW_CONTROLLER_FAILED');
      return 'oiboshi://auth-callback?code=abc';
    };
    expect(
      await authenticateInBrowser('https://x/authorize'),
      'oiboshi://auth-callback?code=abc',
    );
    expect(opened, hasLength(3));
    expect(waits, 2);
  });

  test('開き直しても土台を取れなければ、あきらめてエラーを返す', () async {
    openWebAuth = ({required url, required callbackUrlScheme}) async {
      opened.add(url);
      throw error('ACQUIRE_ROOT_VIEW_CONTROLLER_FAILED');
    };
    await expectLater(
      authenticateInBrowser('https://x/authorize'),
      throwsA(isA<PlatformException>()),
    );
    expect(opened, hasLength(11));
  });

  test('閉じたら null。ほかのエラーは、開き直さずに返す', () async {
    openWebAuth = ({required url, required callbackUrlScheme}) async =>
        throw error('CANCELED');
    expect(await authenticateInBrowser('https://x/authorize'), isNull);

    openWebAuth = ({required url, required callbackUrlScheme}) async {
      opened.add(url);
      throw error('OTHER');
    };
    await expectLater(
      authenticateInBrowser('https://x/authorize'),
      throwsA(isA<PlatformException>()),
    );
    expect(opened, hasLength(1));
    expect(waits, 0);
  });
}
