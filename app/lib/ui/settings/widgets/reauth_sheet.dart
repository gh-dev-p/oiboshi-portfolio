import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/login_method.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/app_snack_bar.dart';
import '../view_models/reauth_viewmodel.dart';
import 'login_provider_icon.dart';

/// 大事な操作の前に、本人を確かめる（機能仕様書 4.1.4.1）。続けてよければ true。
/// 匿名のユーザーと、5分以内に済んでいるときは、そのまま true。ほかは、本人の確認（シート）を出す。
/// ログイン方法を読めなければ、false（操作しない）。
/// [withdraw]（退会）で、Apple を結び付けていて、この端末で Apple を使えるときは、Apple のひも付けを取り消すため、
/// 5分以内に済んでいても、Apple だけで確かめる（機能仕様書 4.1.3。Apple の一時的なコードは5分で切れ、使い捨て）。
Future<bool> ensureReauthenticated(
  BuildContext context,
  WidgetRef ref, {
  bool withdraw = false,
}) async {
  final plan = await ref
      .read(reauthViewModelProvider.notifier)
      .plan(withdraw: withdraw, isIOS: _isIOS);
  if (plan.loadFailed) {
    if (context.mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.settingsReauthLoadFailed,
      );
    }
    return false;
  }
  if (plan.methods.isEmpty) return true;
  if (!context.mounted) return false;
  return await showAppSheet<bool>(
        context,
        builder: (_) => _ReauthSheet(
          methods: plan.methods,
          message: plan.appleOnly
              ? AppLocalizations.of(context)!.settingsReauthAppleMessage
              : null,
        ),
      ) ??
      false;
}

/// 本人の確認（シート）（画面定義書 2.1.7）。
bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

class _ReauthSheet extends ConsumerWidget {
  const _ReauthSheet({required this.methods, this.message});

  final List<LoginMethod> methods;

  /// 説明の文。null なら、いつもの文。
  final String? message;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    LoginMethod method,
  ) async {
    final result = await ref
        .read(reauthViewModelProvider.notifier)
        .reauthenticate(method);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case LoginResult.done:
        Navigator.of(context).pop(true);
      case LoginResult.cancelled:
        break;
      case LoginResult.wrongAccount:
        showAppSnackBar(context, l10n.settingsWrongAccount);
      case LoginResult.alreadyUsed:
      case LoginResult.failed:
        showAppSnackBar(context, l10n.settingsLoginFailed);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // シートを出している間、ViewModel を保つ。
    ref.watch(reauthViewModelProvider);
    final l10n = AppLocalizations.of(context)!;
    final available = LoginProvider.available(isIOS: _isIOS);
    final usable = [
      for (final m in methods)
        if (available.contains(m.provider)) m,
    ];
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.settingsReauthTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              usable.isEmpty
                  ? l10n.settingsReauthUnavailable
                  : message ?? l10n.settingsReauthMessage,
              style: context.textStyles.note,
            ),
          ),
          for (final m in usable)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: LoginProviderButton(
                provider: m.provider,
                label: loginButtonLabel(l10n, m.provider),
                subtitle: m.accountLabel,
                onPressed: () => _run(context, ref, m),
              ),
            ),
        ],
      ),
    );
  }
}
