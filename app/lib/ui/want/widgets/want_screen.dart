import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/sns_account_input.dart';
import '../../../domain/models/sns_service.dart';
import '../../../domain/models/want.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/labeled_field.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/platform_chip.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/viewer_aware_header.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../home/widgets/home_tabs.dart';
import '../view_models/want_viewmodel.dart';

/// 追いたい（画面定義書 2.3.4。機能仕様書（届ける・広める）4.5.1）。
/// 追星にまだいない人を、SNS の URL か ID で申告する。自分が押した一覧と、押した人数を出す。
/// 未登録の人は本人確認なしとして、発信者の一覧（推しを探す）とは別の画面に出す。名前やアイコンは出さない。
class WantScreen extends ConsumerStatefulWidget {
  const WantScreen({super.key, this.initialText = ''});

  /// 入力欄に、はじめから入れておく文字（推しを探すで入れた言葉）。
  final String initialText;

  /// 推しのタブで開く（画面定義書 5.1.8）。
  static Future<void> open(BuildContext context, {String initialText = ''}) =>
      HomeTabs.open(
        context,
        HomeTab.oshi,
        MaterialPageRoute<void>(
          builder: (_) => WantScreen(initialText: initialText),
        ),
      );

  @override
  ConsumerState<WantScreen> createState() => _WantScreenState();
}

class _WantScreenState extends ConsumerState<WantScreen> {
  late final _input = TextEditingController(text: widget.initialText.trim());

  /// ID だけを入れたときに選ぶ SNS。URL なら、URL から決める。
  SnsService? _service;
  var _busy = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// 入力から読み取った SNS と ID。この版で出す SNS（[SnsService.offered]）でなければ null。
  SnsAccountInput? get _parsed {
    final parsed =
        SnsAccountInput.parse(_input.text, service: _service) ??
        SnsAccountInput.parse(_input.text);
    return parsed != null && parsed.service.offered ? parsed : null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final parsed = _parsed;
    if (parsed == null) {
      // URL でも ID でもない、または ID だけで SNS を選んでいない。
      final idOnly = !_input.text.contains('/') && _service == null;
      showAppSnackBar(
        context,
        idOnly ? l10n.wantChooseService : l10n.wantInvalid,
      );
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(wantViewModelProvider.notifier).want(parsed);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case WantAdded():
        _input.clear();
        setState(() => _service = null);
        showAppSnackBar(context, l10n.wantAdded);
      case WantRegistered(:final creatorId):
        showAppSnackBar(context, l10n.wantAlreadyHere);
        await CreatorScreen.open(context, creatorId);
      case WantLimit():
        showAppSnackBar(context, l10n.wantLimit);
      case WantInvalid():
        showAppSnackBar(context, l10n.wantInvalid);
      case WantFailed():
        showAppSnackBar(context, l10n.wantFailed);
    }
  }

  Future<void> _cancel(Want want) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ref
        .read(wantViewModelProvider.notifier)
        .cancel(want.wantedAccountId);
    if (!ok && mounted) showAppSnackBar(context, l10n.wantCancelFailed);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final wants = ref.watch(wantViewModelProvider);
    final parsed = _parsed;
    // URL から SNS が分かれば、そのチップを選んだ形で出す。
    final shownService = parsed?.service ?? _service;
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.wantTitle),
      body: ListView(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              l10n.wantIntro,
              style: context.textStyles.note.copyWith(height: 20 / 13),
            ),
          ),
          LabeledField(
            label: l10n.wantInputLabel,
            child: TextField(
              controller: _input,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: l10n.wantInputHint),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
          ),
          SectionLabel(
            l10n.wantServiceLabel,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in SnsService.offeredValues)
                  PlatformChip(
                    service: s,
                    selected: shownService == s,
                    onTap: () =>
                        setState(() => _service = _service == s ? null : s),
                  ),
              ],
            ),
          ),
          if (parsed != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(l10n.wantParsed, style: context.textStyles.hint),
                  const SizedBox(width: 8),
                  PlatformIcon(parsed.service, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: OneLineText(
                      displayWantAccount(parsed.service, parsed.account),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: PrimaryButton(
              label: l10n.wantSubmit,
              onPressed: _busy || _input.text.trim().isEmpty ? null : _submit,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(l10n.wantPrivacyNote, style: context.textStyles.hint),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 6),
            child: Text(
              l10n.wantListTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          ...switch (wants) {
            AsyncData(:final value) when value.isEmpty => [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(l10n.wantListEmpty, style: context.textStyles.note),
              ),
            ],
            AsyncData(:final value) => [
              for (final w in value)
                _WantRow(want: w, onCancel: () => _cancel(w)),
            ],
            AsyncError() => [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.commonLoadFailedTitle,
                        style: context.textStyles.note,
                      ),
                    ),
                    AppTextButton(
                      label: l10n.commonTryAgain,
                      onPressed: ref.read(wantViewModelProvider.notifier).retry,
                    ),
                  ],
                ),
              ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          },
        ],
      ),
    );
  }
}

/// 自分が押した追いたいの1行。SNS のアイコン・ID・押した人数・本人確認なしの印・取り消す。
class _WantRow extends StatelessWidget {
  const _WantRow({required this.want, required this.onCancel});

  final Want want;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 他人のアイコンは出さない。SNS のアイコンを、発信者のアイコンと同じ丸に入れる。
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.avatarFill,
              shape: BoxShape.circle,
            ),
            child: PlatformIcon(want.service, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneLineText(
                  want.displayAccount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusChip(l10n.wantUnverified, muted: true),
                    const SizedBox(width: 8),
                    Flexible(
                      child: OneLineText(
                        l10n.wantCount(want.wantCount),
                        style: TextStyle(fontSize: 13, color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SmallPillButton(
            label: l10n.wantCancel,
            tonal: true,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
