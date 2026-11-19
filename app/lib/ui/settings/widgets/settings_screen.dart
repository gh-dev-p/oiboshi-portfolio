import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/confirm_dialog.dart';
import '../../core/ui/external_link_dialog.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/search_field.dart';
import '../../core/ui/settings_row.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../../creator_admin/widgets/creator_register_screen.dart';
import '../view_models/settings_viewmodel.dart';
import 'contact_dialog.dart';
import 'display_mode_sheet.dart';
import 'hidden_creators_screen.dart';
import 'language_sheet.dart';
import 'login_methods_screen.dart';
import 'login_sheet.dart';
import 'register_creator_card.dart';
import 'notification_settings_screen.dart';
import 'withdraw_screen.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 設定（画面定義書 2.1.1）。設定のハブ。ファンと発信者で、中身が少し変わる（発信者向けの項目は、発信者のタブ）。
/// 下部ナビの設定のタブの本体（画面定義書 5.1.1）。
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _contact() async {
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(settingsViewModelProvider.notifier);
    final draft = await vm.contactDraft(
      subject: l10n.commonContactSubject,
      body: (userId, version, os) =>
          l10n.commonContactBody(userId, version, os),
      notSignedIn: l10n.commonContactNotSignedIn,
    );
    if (!mounted) return;
    await openContactMail(context, draft: draft, userId: vm.userId);
  }

  Future<void> _createOrLogIn() async {
    final outcome = await showLoginSheet(context);
    if (outcome != null && mounted) showLoginOutcomeSnackBar(context, outcome);
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsLogoutConfirmTitle,
      message: l10n.settingsLogoutConfirmMessage,
      confirmLabel: l10n.settingsLogout,
    );
    if (!confirmed || !mounted) return;
    final ok = await ref
        .read(loadingOverlayProvider.notifier)
        .run(ref.read(settingsViewModelProvider.notifier).signOut);
    if (mounted) {
      showAppSnackBar(
        context,
        ok ? l10n.settingsLoggedOut : l10n.settingsLogoutFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(settingsViewModelProvider);
    final vm = ref.read(settingsViewModelProvider.notifier);
    final owned = state.ownedCreator;
    final loginMethods = state.loginMethods;
    final anonymous = state.anonymous;
    final notifyValue = switch (state.notificationsEnabled) {
      null => '',
      true => l10n.settingsOn,
      false => l10n.settingsOff,
    };
    // 検索。表示言語の名前で比べる。
    final matches = state.matches;
    // 検索で比べる、行の名前（表示言語）。
    final labels = (
      notifications: l10n.settingsNotifications,
      displayMode: l10n.settingsDisplayMode,
      language: l10n.settingsLanguage,
      registerCreator: l10n.settingsRegisterAsCreator,
      loginMethods: l10n.settingsLoginMethods,
      accountEntry: l10n.settingsAccountEntry,
      logout: l10n.settingsLogout,
      hiddenCreators: l10n.settingsHiddenCreators,
      contact: l10n.commonContact,
      terms: l10n.commonTermsOfService,
      privacy: l10n.commonPrivacyPolicy,
      withdraw: l10n.settingsWithdraw,
    );
    // 出す行。「見つかりませんでした」は、出している行だけで判定する（出していない行の名前に合っても、出さない）。
    final show = (
      notifications: matches(labels.notifications),
      displayMode: matches(labels.displayMode),
      language: matches(labels.language),
      // 発信者でないと分かるまでは、「発信者として登録する」のカードを出さない。
      registerCreator:
          state.ownedCreatorLoaded &&
          owned == null &&
          matches(labels.registerCreator),
      loginMethods: !anonymous && matches(labels.loginMethods),
      accountEntry: anonymous && matches(labels.accountEntry),
      logout: !anonymous && matches(labels.logout),
      hiddenCreators: matches(labels.hiddenCreators),
      contact: matches(labels.contact),
      terms: matches(labels.terms),
      privacy: matches(labels.privacy),
      withdraw: matches(labels.withdraw),
    );
    final nothingShown = ![
      show.notifications,
      show.displayMode,
      show.language,
      show.registerCreator,
      show.loginMethods,
      show.accountEntry,
      show.logout,
      show.hiddenCreators,
      show.contact,
      show.terms,
      show.privacy,
      show.withdraw,
    ].any((shown) => shown);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // 固定ビューアを出している間は、ヘッダーを中身と一緒にスクロールして隠す（画面定義書 5.1.2）。
        child: ViewerAwareHeader(
          header: TabHeader(title: l10n.settingsTitle),
          body: ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 16,
            ),
            children: [
              SearchField(
                hintText: l10n.commonSearch,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                onChanged: vm.setQuery,
              ),
              if (show.notifications)
                SettingsRow(
                  icon: Icons.notifications_outlined,
                  label: labels.notifications,
                  value: notifyValue,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  ),
                ),
              if (show.displayMode)
                SettingsRow(
                  icon: Icons.brightness_medium_outlined,
                  label: labels.displayMode,
                  value: l10n.displayMode(state.displayMode),
                  onTap: () => showDisplayModeSheet(context),
                ),
              if (show.language)
                SettingsRow(
                  icon: Icons.language,
                  label: labels.language,
                  value: l10n.appLanguage(state.language),
                  onTap: () => showLanguageSheet(context),
                ),
              if (show.accountEntry ||
                  show.loginMethods ||
                  show.logout ||
                  show.hiddenCreators) ...[
                SectionLabel(l10n.settingsSectionAccount),
                if (show.accountEntry)
                  SettingsRow(
                    icon: Icons.person_outline,
                    label: labels.accountEntry,
                    onTap: _createOrLogIn,
                  ),
                if (show.loginMethods)
                  SettingsRow(
                    icon: Icons.key_outlined,
                    label: labels.loginMethods,
                    value: state.loginMethodsFailed
                        ? l10n.commonLoadFailedTitle
                        : loginMethods == null
                        ? ''
                        : loginMethods
                              .map((m) => m.provider.label)
                              .join(l10n.commonListSeparator),
                    trailing: state.loginMethodsFailed
                        ? AppTextButton(
                            label: l10n.commonRetry,
                            onPressed: vm.retryLoginMethods,
                          )
                        : null,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginMethodsScreen(),
                      ),
                    ),
                  ),
                if (show.logout)
                  SettingsRow(
                    icon: Icons.logout,
                    label: labels.logout,
                    showChevron: false,
                    onTap: _signOut,
                  ),
                if (show.hiddenCreators)
                  SettingsRow(
                    icon: Icons.visibility_off_outlined,
                    label: labels.hiddenCreators,
                    value: switch (state.hiddenCreatorCount) {
                      null => '',
                      final count => l10n.settingsHiddenCreatorCount(count),
                    },
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HiddenCreatorsScreen(),
                      ),
                    ),
                  ),
              ],
              if (show.registerCreator)
                RegisterCreatorCard(
                  title: labels.registerCreator,
                  // アカウント作成の前は、押せない（機能仕様書 4.6.1）。
                  enabled: !anonymous,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreatorRegisterScreen(),
                    ),
                  ),
                ),
              if (show.contact || show.terms || show.privacy) ...[
                SectionLabel(l10n.settingsSectionSupport),
                if (show.contact)
                  SettingsRow(
                    icon: Icons.mail_outline,
                    label: labels.contact,
                    onTap: _contact,
                  ),
                if (show.terms)
                  SettingsRow(
                    icon: Icons.description_outlined,
                    label: labels.terms,
                    onTap: () => openPageOrNotify(context, termsUrl),
                  ),
                if (show.privacy)
                  SettingsRow(
                    icon: Icons.security,
                    label: labels.privacy,
                    onTap: () => openPageOrNotify(context, privacyUrl),
                  ),
              ],
              if (show.withdraw) ...[
                const SizedBox(height: 8),
                SettingsRow(
                  icon: Icons.person_remove_outlined,
                  label: labels.withdraw,
                  destructive: true,
                  showChevron: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WithdrawScreen(),
                    ),
                  ),
                ),
              ],
              if (state.searching && nothingShown)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      l10n.commonNotFound,
                      style: context.textStyles.bodySecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
