import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/labeled_field.dart';
import '../view_models/login_viewmodel.dart';

/// アプリ運営用ログイン（画面定義書 2.1.11）。アカウント作成／ログイン（シート）の中身を切り替えて出す。
/// 運営が作ったアカウントに、メールアドレスとパスワードで入る（機能仕様書 4.1.4）。
/// 新しい登録と、パスワードを忘れたときの手続きは置かない。
/// 入れたら [onLoggedIn]、戻るで [onBack]。
class AdminLoginForm extends ConsumerStatefulWidget {
  const AdminLoginForm({
    super.key,
    required this.onBack,
    required this.onLoggedIn,
  });

  final VoidCallback onBack;
  final VoidCallback onLoggedIn;

  @override
  ConsumerState<AdminLoginForm> createState() => _AdminLoginFormState();
}

class _AdminLoginFormState extends ConsumerState<AdminLoginForm> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_refresh);
    _password.addListener(_refresh);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _filled =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final outcome = await ref
        .read(loginViewModelProvider.notifier)
        .logInWithPassword(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    final l10n = AppLocalizations.of(context)!;
    switch (outcome) {
      case LoginOutcome.loggedIn:
      case LoginOutcome.created:
        widget.onLoggedIn();
      case LoginOutcome.invalidCredentials:
        showAppSnackBar(context, l10n.settingsAdminLoginInvalid);
      case LoginOutcome.tooManyAttempts:
        showAppSnackBar(context, l10n.settingsAdminLoginTooMany);
      case LoginOutcome.cancelled:
      case LoginOutcome.failed:
        showAppSnackBar(context, l10n.settingsLoginFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: _busy ? null : widget.onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: Icon(
                  Icons.chevron_left,
                  size: 24,
                  color: context.colors.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.settingsAdminLogin,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Text(
            l10n.settingsAdminLoginLead,
            style: context.textStyles.note,
          ),
        ),
        LabeledField(
          label: l10n.settingsAdminLoginEmail,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
        ),
        LabeledField(
          label: l10n.settingsAdminLoginPassword,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: _password,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (_filled && !_busy) _submit();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: PrimaryButton(
            label: l10n.settingsAdminLoginSubmit,
            onPressed: _filled && !_busy ? _submit : null,
          ),
        ),
      ],
    );
  }
}
