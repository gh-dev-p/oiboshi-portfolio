import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';

/// お問い合わせの本文に入れる、アプリのバージョンと OS。
class AppInfoService {
  const AppInfoService();

  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (${info.buildNumber})';
  }

  String osName() =>
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
}
