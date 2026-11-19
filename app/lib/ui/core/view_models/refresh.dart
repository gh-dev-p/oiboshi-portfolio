import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../../config/app_constants.dart';

/// 一覧の読み直し（画面定義書 5.1.4）。[refreshInterval] ごとに、Provider を作り直す。
/// 作り直しの間は前の値を保ったまま読み込み、失敗しても前の値を残す（更新の失敗はスナックバーで知らせる）。
void refreshPeriodically(Ref ref) {
  final timer = Timer(refreshInterval, ref.invalidateSelf);
  ref.onDispose(timer.cancel);
}

/// 読み直す（「もう一度試す」、引いて更新）。[providers] を、並べた順に作り直す。
/// [awaiting] を渡したら、それが返す読み込みが終わるまで待つ（失敗しても投げない。失敗は、各画面が出す）。
Future<void> reloadFrom(
  Ref ref,
  List<ProviderOrFamily> providers, {
  Future<Object?> Function()? awaiting,
}) async {
  for (final p in providers) {
    ref.invalidate(p);
  }
  if (awaiting == null) return;
  try {
    await awaiting();
  } catch (_) {}
}
