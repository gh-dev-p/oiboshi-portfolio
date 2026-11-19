// 【仮】Instagram の DM での確認（機能仕様書 4.6.2.1、画面定義書 2.3.2.1）。
// Meta の審査が通るまでの、一時的な仕組み。通ったら、このファイルごと外す。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/instagram_dm.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../../utils/open_url.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_sheet.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/labeled_field.dart';
import '../view_models/instagram_dm_viewmodel.dart';

/// DM の確認のシートを開く。[creatorId] が null なら、発信者として登録の手順から。
Future<void> showInstagramDmSheet(BuildContext context, String? creatorId) =>
    showAppSheet(
      context,
      builder: (_) => _InstagramDmSheet(creatorId: creatorId),
    );

class _InstagramDmSheet extends ConsumerStatefulWidget {
  const _InstagramDmSheet({required this.creatorId});

  final String? creatorId;

  @override
  ConsumerState<_InstagramDmSheet> createState() => _InstagramDmSheetState();
}

class _InstagramDmSheetState extends ConsumerState<_InstagramDmSheet> {
  final _account = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  InstagramDmViewModel get _viewModel =>
      ref.read(instagramDmViewModelProvider(widget.creatorId).notifier);

  Future<void> _request() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final result = await _viewModel.request(_account.text);
    if (!mounted) return;
    setState(() => _busy = false);
    final message = switch (result) {
      InstagramDmRequestResult.requested => null,
      InstagramDmRequestResult.invalid => l10n.creatorAdminDmInvalid,
      InstagramDmRequestResult.duplicate => l10n.creatorAdminLinkDuplicate,
      InstagramDmRequestResult.failed => l10n.creatorAdminDmFailed,
    };
    if (message != null) showAppSnackBar(context, message);
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    final ok = await _viewModel.cancel();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      showAppSnackBar(context, l10n.creatorAdminDmCancelFailed);
    }
  }

  Future<void> _copy(String code) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) showAppSnackBar(context, l10n.creatorAdminDmCopied);
  }

  Future<void> _open(String dmAccount) async {
    final l10n = AppLocalizations.of(context)!;
    final opened = await openUrl(Uri.https('ig.me', '/m/$dmAccount'));
    if (!opened && mounted) showAppSnackBar(context, l10n.commonPageOpenFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(instagramDmViewModelProvider(widget.creatorId));
    final dm = state.value;
    final dmAccount = dm?.dmAccount;
    final request = dm?.request;
    return Padding(
      // キーボードの上に出す。
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppSheet(
        scrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetTitle(l10n.creatorAdminDmTitle),
            // 読めなかった・その間に DM の手順を止めた。
            if (state.hasError || (state.hasValue && dmAccount == null))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.creatorAdminDmFailed,
                  style: context.textStyles.note,
                ),
              )
            else if (dmAccount == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (request == null)
              ..._requestForm(l10n, dmAccount)
            else
              ..._pending(l10n, dmAccount, request),
          ],
        ),
      ),
    );
  }

  List<Widget> _requestForm(AppLocalizations l10n, String dmAccount) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        l10n.creatorAdminDmIntro(dmAccount),
        style: context.textStyles.note,
      ),
    ),
    LabeledField(
      label: l10n.creatorAdminDmUsernameLabel,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        controller: _account,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.visiblePassword,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(prefixText: '@'),
        onChanged: (_) => setState(() {}),
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: PrimaryButton(
        label: l10n.creatorAdminDmRequest,
        onPressed: _busy || _account.text.trim().isEmpty ? null : _request,
      ),
    ),
  ];

  List<Widget> _pending(
    AppLocalizations l10n,
    String dmAccount,
    InstagramDmRequest request,
  ) {
    final c = context.colors;
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          l10n.creatorAdminDmTarget(request.account),
          style: context.textStyles.note,
        ),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: c.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                request.code,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: c.textPrimary,
                ),
              ),
            ),
            AppTextButton(
              label: l10n.creatorAdminDmCopy,
              onPressed: () => _copy(request.code),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Text(
          l10n.creatorAdminDmSendTo(dmAccount),
          style: context.textStyles.note,
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: PrimaryButton(
          label: l10n.creatorAdminDmOpen,
          onPressed: () => _open(dmAccount),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Text(
          l10n.creatorAdminDmNote(fullDate(request.expiresAt.toLocal(), l10n)),
          style: context.textStyles.hint,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: AppTextButton(
            label: l10n.creatorAdminDmCancel,
            onPressed: _busy ? null : _cancel,
          ),
        ),
      ),
    ];
  }
}
