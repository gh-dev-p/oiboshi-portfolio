import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/service_providers.dart';

/// サインイン済みのユーザー ID。サインインしていなければ、匿名でサインインする（機能仕様書 4.1.1）。
/// データを読む Provider は、先にこれを待つ。失敗したら、各画面が「読み込めない」を出し、
/// 「もう一度試す」でこの Provider を作り直す。
/// 端末のセッションが、ここで覚えているのと違うユーザーに切り替わったら、どの経路で切り替わっても作り直す
/// （依存する Provider も、それで作り直される。機能仕様書 4.1.4）。セッションが消えただけ（ログアウトの途中）では
/// 作り直さない（ログアウトは、設定の ViewModel が作り直す）。
final authSessionProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final userId = await repo.ensureSignedIn();
  final sub = repo.userIdChanges.listen((id) {
    if (id != null && id != userId) ref.invalidateSelf();
  });
  ref.onDispose(sub.cancel);
  return userId;
});

/// サインインを待ってから、[read] でデータを読む。データを読む Provider の初めに使う（アーキテクチャ設計書 4.2）。
/// [authSessionProvider] を watch するので、サインインし直すと、呼んだ Provider も作り直される。
Future<T> withSession<T>(
  Ref ref,
  FutureOr<T> Function(String userId) read,
) async => read(await ref.watch(authSessionProvider.future));
