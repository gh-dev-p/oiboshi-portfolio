import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/login_method.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/login_methods_viewmodel.dart';
import 'login_provider_icon.dart';
import 'reauth_sheet.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/viewer_aware_header.dart';

/// ログイン方法（画面定義書 2.1.5）。Apple・Google・X・Twitch のログインを結び付ける・外す。
class LoginMethodsScreen extends ConsumerWidget {
  const LoginMethodsScreen({super.key});

  Future<void> _link(
    BuildContext context,
    WidgetRef ref,
    LoginProvider provider,
  ) async {
    // 結び付けると、そのログインでアカウントに入れるので、先に本人を確かめる（機能仕様書 4.1.4.1）。
    if (!await ensureReauthenticated(context, ref) || !context.mounted) return;
    final result = await ref
        .read(loginMethodsViewModelProvider.notifier)
        .link(provider);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result) {
      LoginResult.done => l10n.settingsLoginLinked(provider.label),
      LoginResult.alreadyUsed => l10n.settingsAccountAlreadyUsed,
      LoginResult.failed || LoginResult.wrongAccount => l10n.settingsLinkFailed,
      LoginResult.cancelled => null,
    };
    if (message != null) showAppSnackBar(context, message);
  }

  Future<void> _unlink(
    BuildContext context,
    WidgetRef ref,
    LoginMethod method,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final label = method.provider.label;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsUnlinkConfirmTitle(label),
      message: l10n.settingsUnlinkConfirmMessage(label),
      confirmLabel: l10n.settingsUnlink,
    );
    if (!confirmed || !context.mounted) return;
    if (!await ensureReauthenticated(context, ref) || !context.mounted) return;
    // 待っている間は、幕で覆って押せなくする（「外す」の二重押しを防ぐ）。
    final ok = await ref
        .read(loadingOverlayProvider.notifier)
        .run(
          () => ref.read(loginMethodsViewModelProvider.notifier).unlink(method),
        );
    if (context.mounted) {
      showAppSnackBar(
        context,
        ok ? l10n.settingsUnlinked(label) : l10n.settingsUnlinkFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(loginMethodsViewModelProvider);
    if (state.hasError && !state.hasValue) {
      return HeaderScaffold(
        appBar: ScreenAppBar(title: l10n.settingsLoginMethods),
        body: StateView.error(
          onRetry: ref.read(loginMethodsViewModelProvider.notifier).retry,
        ),
      );
    }
    // 読めるまでは、行をスケルトンにする（押せない。画面定義書 5.1.3）。
    final loading = !state.hasValue;
    final methods = state.value ?? const <LoginMethod>[];
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.settingsLoginMethods),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.settingsLoginMethodsDescription,
              style: context.textStyles.note,
            ),
          ),
          if (loading)
            for (final _ in LoginProvider.available(isIOS: isIOS))
              const SkeletonIconRow()
          else
            // Apple は、iOS だけで結び付けられる。ほかの端末でも、結び付け済みなら出す（外せるように）。
            for (final p in LoginProvider.values)
              if (LoginProvider.available(isIOS: isIOS).contains(p) ||
                  methods.any((m) => m.provider == p))
                _MethodRow(
                  provider: p,
                  method: methods.where((m) => m.provider == p).firstOrNull,
                  // 最後の1つは外せない。
                  canUnlink: methods.length > 1,
                  onLink: () => _link(context, ref, p),
                  onUnlink: (m) => _unlink(context, ref, m),
                ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Text(
              l10n.settingsLoginMethodsNote,
              style: context.textStyles.hint,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.provider,
    required this.method,
    required this.canUnlink,
    required this.onLink,
    required this.onUnlink,
  });

  final LoginProvider provider;
  final LoginMethod? method;
  final bool canUnlink;
  final VoidCallback onLink;
  final ValueChanged<LoginMethod> onUnlink;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final m = method;
    final Widget trailing;
    if (m == null) {
      trailing = SmallPillButton(label: l10n.settingsLink, onPressed: onLink);
    } else if (canUnlink) {
      trailing = AppTextButton(
        label: l10n.settingsUnlink,
        onPressed: () => onUnlink(m),
      );
    } else {
      trailing = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          LoginProviderIcon(provider, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                OneLineText(
                  m == null
                      ? l10n.commonNotSet
                      : (m.accountLabel ?? l10n.settingsLoginMethodSet),
                  style: TextStyle(
                    fontSize: 12,
                    color: m == null ? c.textTertiary : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
