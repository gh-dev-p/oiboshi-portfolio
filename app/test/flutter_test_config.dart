import 'dart:async';

import 'package:visibility_detector/visibility_detector.dart';

/// すべてのテストの前に呼ばれる（flutter_test の決まり）。
/// 画面に出たかの判定（投稿が見られた数）を、待たずにすぐ知らせる（判定の待ちのタイマーが、テストの終わりに残らないように）。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  await testMain();
}
