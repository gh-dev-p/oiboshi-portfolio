import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../domain/models/creator.dart';
import '../../../domain/models/creator_settings.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/state_view.dart';
import '../../settings/widgets/reauth_sheet.dart';
import '../view_models/account_link_viewmodel.dart';
import '../view_models/display_contents_viewmodel.dart';
import '../view_models/instagram_dm_viewmodel.dart';
import '../view_models/plan_viewmodel.dart';
import 'instagram_dm_sheet.dart';
import 'upcoming_platforms.dart';
import '../../core/ui/verified_chip.dart';
import '../../core/ui/viewer_aware_header.dart';

/// アカウント連携（画面定義書 2.3.2）。SNS のアカウントを連携し、本人のものであることを確かめる。
/// YouTube・ツイキャス・Twitch・Instagram・X を、OAuth で連携する。
/// 【仮】Meta の審査が通るまでは、Instagram を DM で確かめる（機能仕様書 4.6.2.1）。受け先がなければ、OAuth に戻る。
/// この版で出さない SNS（v1.0.0 の Instagram・ツイキャス。[SnsService.offered]）は、「準備中」で並べ、連携も DM の手順もしない（機能仕様書 4.6.2）。
/// 発信者として登録の手順から開いたとき（発信者がまだいない）は、登録待ちの連携（機能仕様書 4.6.1）を扱う。
///
/// 発信者メニューの「SNS」から開いたとき（[creatorId] がある）は、「SNS」の画面（画面定義書 2.3.2）：
/// SNS ごとの面に、連携の行と、追星に出す内容の切り替え（もとの「表示するコンテンツ」。2.3.3）をまとめて出す（2026-11-19 本人）。
class AccountLinkScreen extends ConsumerWidget {
  const AccountLinkScreen({super.key, this.creatorId});

  /// 登録の手順から開いたときは null（まだ発信者がいない）。
  final String? creatorId;

  Future<void> _link(
    BuildContext context,
    WidgetRef ref,
    SnsService service,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(accountLinkViewModelProvider(creatorId).notifier)
        .linkAccount(service);
    if (!context.mounted) return;
    final message = switch (result) {
      AccountLinkResult.linked => l10n.creatorAdminLinked(l10n.sns(service)),
      AccountLinkResult.reclaimable => l10n.creatorAdminLinkReclaimable,
      AccountLinkResult.duplicate => l10n.creatorAdminLinkDuplicate,
      AccountLinkResult.noChannel => l10n.creatorAdminLinkNoChannel,
      AccountLinkResult.failed => l10n.creatorAdminLinkFailed,
      AccountLinkResult.cancelled => null,
    };
    if (message != null) showAppSnackBar(context, message);
    // 登録の画面に、取り戻しの案内を出すので、戻る（機能仕様書 4.6.1.2）。
    if (result == AccountLinkResult.reclaimable && creatorId == null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    SnsService service,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.creatorAdminUnlinkConfirmTitle(l10n.sns(service)),
      // 登録の手順の連携は、まだ何も取得していない。
      message: creatorId == null
          ? l10n.creatorAdminUnlinkConfirmMessage
          : l10n.creatorAdminUnlinkConfirmHeldMessage,
      confirmLabel: l10n.creatorAdminUnlinkConfirmAction,
    );
    if (!confirmed || !context.mounted) return;
    // 連携の解除の前に、本人を確かめる（機能仕様書 4.1.4.1）。
    if (!await ensureReauthenticated(context, ref) || !context.mounted) return;
    final ok = await ref
        .read(accountLinkViewModelProvider(creatorId).notifier)
        .unlinkAccount(service);
    if (context.mounted) {
      showAppSnackBar(
        context,
        ok
            ? l10n.creatorAdminUnlinked(l10n.sns(service))
            : l10n.creatorAdminUnlinkFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // 登録の手順から開いたとき（creatorId が null）は、登録待ちの連携を出す。
    final state = ref.watch(accountLinkViewModelProvider(creatorId));
    final id = creatorId;
    // 発信者メニューから開いたときは、出す内容の設定も読む（もとの「表示するコンテンツ」）。
    final display = id == null
        ? null
        : ref.watch(displayContentsViewModelProvider(id));
    final title = id == null
        ? l10n.creatorAdminAccountLinkTitle
        : l10n.creatorAdminSnsTitle;
    if (state.hasError || (display?.hasError ?? false)) {
      return HeaderScaffold(
        appBar: ScreenAppBar(title: title),
        body: StateView.error(
          onRetry: () {
            ref.read(accountLinkViewModelProvider(creatorId).notifier).retry();
            if (id != null) {
              ref.read(displayContentsViewModelProvider(id).notifier).retry();
            }
          },
        ),
      );
    }
    // 【仮】Instagram の DM での確認。読めなければ、OAuth に替えず、読めなかったことと「再試行」を出す（2.3.2）。
    // Instagram を出さない版（v1.0.0）は、DM の状態を読まない。
    final dm = SnsService.instagram.offered
        ? ref.watch(instagramDmViewModelProvider(creatorId))
        : null;
    final dmState = dm?.value;
    // 読めるまでは、行をスケルトンにする（押せない。画面定義書 5.1.3）。
    final loading =
        !state.hasValue ||
        dm != null && !dm.hasValue && !dm.hasError ||
        display != null && !display.hasValue;
    final accounts = state.value ?? const <SnsService, CreatorAccount>{};
    final data = display?.value;
    // X の注記の月額は、ストアの価格。読めないあいだ（読み込み中・読めない・課金を使えない）は、アプリに持つ月額。
    final xPrice = id == null ? null : ref.watch(xOptionPriceProvider).value;
    final xPriceLabel = xPrice == null
        ? l10n.priceYen('$xOptionYen')
        : l10n.planPrice(xPrice);

    /// 連携の行 [row] に、[service] の出す内容の切り替えを足した面にする。登録の手順では、行だけ。
    Widget card(Widget row, SnsService service) {
      if (id == null || data == null) return row;
      // 選べるのは、確認済みのアカウントだけ。X は、X を取得する発信者（X連携プランか、X を含むプラン）だけ。
      final verified = data.isVerified(service);
      final needsOption = service == SnsService.x && !data.creator.xOption;
      final enabled = verified && !needsOption;
      return _SnsCard(
        row: row,
        note: verified && needsOption
            ? l10n.creatorAdminDisplayNeedsXOption(xPriceLabel)
            : null,
        switches: [
          for (final content in DisplayContent.availableFor(service))
            _SwitchRow(
              label: l10n.displayContent(content),
              value: enabled && data.isDisplayEnabled(service, content),
              enabled: enabled,
              onChanged: (v) async {
                final ok = await ref
                    .read(displayContentsViewModelProvider(id).notifier)
                    .setDisplay(service, content, v);
                if (!ok && context.mounted) {
                  showAppSnackBar(context, l10n.commonSettingChangeFailed);
                }
              },
            ),
        ],
      );
    }

    /// 準備中の行 [row] に、オフで操作できない切り替え（[contents]）を足した面にする。登録の手順では、行だけ。
    Widget comingSoonCard(Widget row, List<String> contents) => id == null
        ? row
        : _SnsCard(
            row: row,
            switches: [
              for (final label in contents)
                _SwitchRow(
                  label: label,
                  value: false,
                  enabled: false,
                  onChanged: null,
                ),
            ],
          );

    return HeaderScaffold(
      appBar: ScreenAppBar(title: title),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.creatorAdminAccountLinkIntro,
              style: context.textStyles.note,
            ),
          ),
          if (id != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                l10n.creatorAdminDisplayContentsHideNote,
                style: context.textStyles.hint,
              ),
            ),
          if (loading)
            for (final _ in SnsService.values) const SkeletonIconRow()
          else
            for (final s in SnsService.offeredValues)
              if (s == SnsService.instagram &&
                  dm!.hasError &&
                  !(accounts[s]?.verified ?? false))
                card(
                  _LinkRow(
                    icon: PlatformIcon(s, size: 36),
                    name: l10n.sns(s),
                    loadFailed: true,
                    onLink: ref
                        .read(instagramDmViewModelProvider(creatorId).notifier)
                        .retry,
                  ),
                  s,
                )
              else if (s == SnsService.instagram &&
                  (dmState?.enabled ?? false) &&
                  !(accounts[s]?.verified ?? false))
                // 【仮】DM で確かめる（画面定義書 2.3.2.1）。
                card(
                  _LinkRow(
                    icon: PlatformIcon(s, size: 36),
                    name: l10n.sns(s),
                    account: dmState!.request?.account ?? accounts[s]?.account,
                    pending: dmState.request != null,
                    onLink: () => showInstagramDmSheet(context, creatorId),
                  ),
                  s,
                )
              else
                card(
                  _LinkRow(
                    icon: PlatformIcon(s, size: 36),
                    name: l10n.sns(s),
                    account: accounts[s]?.account,
                    verified: accounts[s]?.verified ?? false,
                    onLink: () => _link(context, ref, s),
                    onUnlink: () => _unlink(context, ref, s),
                  ),
                  s,
                ),
          // この版で出さない SNS（v1.0.0 の Instagram）は、準備中のプラットフォームの先頭に並べる（画面定義書 5.1.7）。
          for (final s in SnsService.values)
            if (!s.offered)
              comingSoonCard(
                _LinkRow(
                  icon: PlatformIcon(s, size: 36),
                  name: l10n.sns(s),
                  comingSoon: true,
                ),
                [
                  for (final content in DisplayContent.availableFor(s))
                    l10n.displayContent(content),
                ],
              ),
          for (final p in UpcomingPlatform.values)
            comingSoonCard(
              _LinkRow(
                icon: UpcomingPlatformIcon(p, size: 36),
                name: p.label(l10n),
                comingSoon: true,
              ),
              [p.contents(l10n)],
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Text(
              l10n.creatorAdminAccountLinkNote,
              style: context.textStyles.hint,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.name,
    this.account,
    this.verified = false,
    this.pending = false,
    this.loadFailed = false,
    this.comingSoon = false,
    this.onLink,
    this.onUnlink,
  });

  final Widget icon;
  final String name;
  final String? account;
  final bool verified;

  /// 【仮】Instagram の DM の確認を待っている（機能仕様書 4.6.2.1）。押すと [onLink]。
  final bool pending;

  /// 【仮】Instagram の DM の状態を読めなかった。「再試行」を出し、押すと [onLink]。
  final bool loadFailed;
  final bool comingSoon;
  final VoidCallback? onLink;

  /// 確認済みの行を押したとき（連携の解除）。
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final Widget trailing;
    if (comingSoon) {
      trailing = StatusChip(
        l10n.commonComingSoon,
        background: c.surfaceVariant,
        foreground: c.textSecondary,
      );
    } else if (verified) {
      trailing = const VerifiedChip();
    } else if (loadFailed) {
      trailing = SmallPillButton(label: l10n.commonRetry, onPressed: onLink);
    } else if (pending) {
      trailing = StatusChip(
        l10n.creatorAdminDmPending,
        background: c.surfaceVariant,
        foreground: c.textSecondary,
      );
    } else {
      trailing = SmallPillButton(
        label: l10n.creatorAdminLinkAction,
        onPressed: onLink,
      );
    }
    return Opacity(
      opacity: comingSoon ? 0.5 : 1,
      child: InkWell(
        onTap: comingSoon
            ? null
            : verified
            ? onUnlink
            : pending
            ? onLink
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      loadFailed
                          ? l10n.commonLoadFailedTitle
                          : account == null
                          ? l10n.creatorAdminNotLinked
                          : '@$account',
                      style: TextStyle(
                        fontSize: 12,
                        color: account == null
                            ? c.textTertiary
                            : c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// 「SNS」の画面の、SNS ごとの面（連携の行と、出す内容の切り替え）。準備中は、行と切り替えがそれぞれ薄くなる。
class _SnsCard extends StatelessWidget {
  const _SnsCard({required this.row, required this.switches, this.note});

  final Widget row;
  final List<Widget> switches;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return SurfacePanel(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          if (note case final note?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(note, style: context.textStyles.hint),
            ),
          ...switches,
        ],
      ),
    );
  }
}

/// 出す内容の1行（スイッチ）。
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.divider)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: c.textPrimary),
              ),
            ),
            AppSwitch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    );
  }
}
