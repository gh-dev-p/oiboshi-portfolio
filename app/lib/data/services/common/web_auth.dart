import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// SNS のログイン・アカウント連携のあと、アプリに戻すスキーム。
/// Supabase の Redirect URLs と、サーバーの `_shared/account_link.ts` の `APP_CALLBACK_SCHEME` に合わせる。
const appCallbackScheme = 'oiboshi';

/// ブラウザを乗せる土台の画面を取れなかったときのエラー（`flutter_web_auth_2` の iOS）。
const _rootViewControllerFailed = 'ACQUIRE_ROOT_VIEW_CONTROLLER_FAILED';

/// 土台を取れなかったときに、開き直す回数と間隔（tech-risks.md 2.11）。合わせて 2 秒まで待つ。
const _openRetries = 10;
const _openRetryInterval = Duration(milliseconds: 200);

/// ブラウザを開く処理。テストで差し替える。
@visibleForTesting
Future<String> Function({
  required String url,
  required String callbackUrlScheme,
})
openWebAuth = ({required url, required callbackUrlScheme}) =>
    FlutterWebAuth2.authenticate(
      url: url,
      callbackUrlScheme: callbackUrlScheme,
    );

/// 開き直すまで待つ処理。テストで差し替える。
@visibleForTesting
Future<void> Function(Duration) waitBeforeRetry = Future<void>.delayed;

/// アプリ内のブラウザで [url] を開き、[appCallbackScheme] で戻ってきた URL を返す。閉じたら null。
/// iOS では、前のブラウザが閉じている途中に続けて開くと（アカウント作成／ログインで、結び付けを断られたあとの
/// ログインなど）、乗せる土台の画面を取れずに失敗する。そのときは、少し待って開き直す。
Future<String?> authenticateInBrowser(String url) async {
  for (var attempt = 0; ; attempt++) {
    try {
      return await openWebAuth(url: url, callbackUrlScheme: appCallbackScheme);
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') return null;
      if (e.code == _rootViewControllerFailed && attempt < _openRetries) {
        await waitBeforeRetry(_openRetryInterval);
        continue;
      }
      rethrow;
    }
  }
}
