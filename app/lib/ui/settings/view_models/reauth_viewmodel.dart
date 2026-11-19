import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/login_method.dart';
import 'settings_providers.dart';

/// 大事な操作の前の、本人の確認（シート）の出し方（機能仕様書 4.1.4.1）。
class ReauthPlan {
  const ReauthPlan({
    this.methods = const [],
    this.appleOnly = false,
    this.loadFailed = false,
  });

  /// シートに出すログイン方法。空なら、シートを出さずに続けてよい。
  final List<LoginMethod> methods;

  /// Apple だけで確かめるか（退会で、Apple のひも付けを取り消すため）。
  final bool appleOnly;

  /// ログイン方法を読めなかったか（操作しない）。
  final bool loadFailed;
}

/// 本人の確認（シート）（画面定義書 2.1.7）と、シートを出すかの判断。
class ReauthViewModel extends Notifier<void> {
  @override
  void build() {}

  /// 操作の前に、本人の確認が要るかを決める。
  /// 匿名のユーザーと、5分以内に済んでいるときは、要らない。
  /// [withdraw]（退会）で、Apple を結び付けていて、この端末で Apple を使えるとき（[isIOS]）は、
  /// 5分以内に済んでいても、Apple だけで確かめる（機能仕様書 4.1.3。Apple の一時的なコードは5分で切れ、使い捨て）。
  Future<ReauthPlan> plan({required bool withdraw, required bool isIOS}) async {
    // 読んでいる間に捨てられても続くように、先に取っておく（この ViewModel より長く生きる）。
    final reauth = ref.read(reauthProvider.notifier);
    final List<LoginMethod> methods;
    try {
      methods = await ref.read(loginMethodsProvider.future);
    } catch (_) {
      return const ReauthPlan(loadFailed: true);
    }
    final apple = withdraw && isIOS
        ? methods.where((m) => m.provider == LoginProvider.apple).firstOrNull
        : null;
    if (apple != null) return ReauthPlan(methods: [apple], appleOnly: true);
    if (!reauth.isRequired(methods)) return const ReauthPlan();
    return ReauthPlan(methods: methods);
  }

  /// 結び付けた [method] で、もう一度ログインする。
  Future<LoginResult> reauthenticate(LoginMethod method) =>
      ref.read(reauthProvider.notifier).reauthenticate(method);
}

final reauthViewModelProvider =
    NotifierProvider.autoDispose<ReauthViewModel, void>(ReauthViewModel.new);
