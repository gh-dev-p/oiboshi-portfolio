import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 初回起動の引き継ぎで使う、クリップボード（届ける・広める仕様書 4.3.4、tech-risks 2.31）。
class ClipboardService {
  const ClipboardService();

  static const _channel = MethodChannel('com.example.oiboshi/clipboard');

  /// URL らしいものがあるか。中身を読まないので、iOS の「ペーストを許可」の確認は出ない（`ios/Runner/AppDelegate.swift`）。
  /// iOS 以外は、文字があるか（これも確認を出さない）で代わりにする。
  Future<bool> hasProbableUrl() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _channel.invokeMethod<bool>('hasProbableWebUrl') ?? false;
    }
    return Clipboard.hasStrings();
  }

  /// 中身を読む。iOS では「ペーストを許可」の確認が出る。許可されなければ null。
  /// iOS は、URL らしい部分だけを非同期に読む（確認を待つあいだ、画面を止めない。`ios/Runner/AppDelegate.swift`）。
  Future<String?> readText() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _channel.invokeMethod<String>('readProbableWebUrl');
    }
    return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
  }
}
