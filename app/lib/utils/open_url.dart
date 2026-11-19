import 'package:url_launcher/url_launcher.dart';

/// 外部のアプリ・ブラウザで URL を開く。開けなければ false。
Future<bool> openUrl(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
