import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/login_method.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/app_snack_bar.dart';
import '../view_models/login_viewmodel.dart';
import 'admin_login_form.dart';
import 'login_provider_icon.dart';

/// アカウント作成／ログイン（シート）（画面定義書 2.1.6）。初めてのアカウントなら、いまのユーザーに結び付け
/// （アカウント作成）、使ったことのあるアカウントなら、そのユーザーに入る（ログイン。機能仕様書 4.1.4）。
/// [forCreator] が真なら、発信者として登録するために開いたときの説明を付ける。
/// 済んだら [LoginOutcome.created] か [LoginOutcome.loggedIn]、閉じたら null。
Future<LoginOutcome?> showLoginSheet(
  BuildContext context, {
  bool forCreator = false,
}) => showAppSheet<LoginOutcome>(
  context,
  builder: (_) => _LoginSheet(forCreator: forCreator),
);

/// アカウント作成／ログインのあとのスナックバー。
void showLoginOutcomeSnackBar(BuildContext context, LoginOutcome outcome) {
  final l10n = AppLocalizations.of(context)!;
  showAppSnackBar(
    context,
    outcome == LoginOutcome.created
        ? l10n.settingsAccountCreated
        : l10n.settingsSignedIn,
  );
}

class _LoginSheet extends ConsumerStatefulWidget {
  const _LoginSheet({required this.forCreator});

  final bool forCreator;

  @override
  ConsumerState<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<_LoginSheet> {
  /// アプリ運営用ログイン（画面定義書 2.1.11）に切り替えたか。
  var _admin = false;

  bool get forCreator => widget.forCreator;

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    LoginProvider provider,
  ) async {
    final outcome = await ref
        .read(loginViewModelProvider.notifier)
        .continueWith(provider);
    if (!context.mounted) return;
    switch (outcome) {
      case LoginOutcome.created:
      case LoginOutcome.loggedIn:
        Navigator.of(context).pop(outcome);
      case LoginOutcome.cancelled:
        break;
      case LoginOutcome.invalidCredentials:
      case LoginOutcome.tooManyAttempts:
      case LoginOutcome.failed:
        showAppSnackBar(
          context,
          AppLocalizations.of(context)!.settingsLoginFailed,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_admin) {
      return Padding(
        // キーボードが出ても、入力欄と「ログイン」が隠れないようにする。
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AppSheet(
          scrollable: true,
          child: AdminLoginForm(
            onBack: () => setState(() => _admin = false),
            // 入れたら、シートも閉じる（ログインと同じ）。
            onLoggedIn: () => Navigator.of(context).pop(LoginOutcome.loggedIn),
          ),
        ),
      );
    }
    return AppSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(l10n.settingsAccountEntry),
          // 説明は置かない（2026-11-10 本人）。発信者として登録するために開いたときだけ、一言を添える。
          if (forCreator)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.settingsLoginSheetCreatorLead,
                style: context.textStyles.note,
              ),
            )
          else
            const SizedBox(height: 4),
          for (final p in LoginProvider.available(
            isIOS: defaultTargetPlatform == TargetPlatform.iOS,
          ))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: LoginProviderButton(
                provider: p,
                label: loginButtonLabel(l10n, p, continueLabel: true),
                onPressed: () => _run(context, ref, p),
              ),
            ),
          // アプリ運営用ログイン（画面定義書 2.1.11）。審査の人のためのもの。ふつうのユーザーにも見えるが、目立たせない。
          Center(
            child: AppTextButton(
              label: l10n.settingsAdminLogin,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: context.colors.textSecondary,
              onPressed: () => setState(() => _admin = true),
            ),
          ),
        ],
      ),
    );
  }
}
