import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/formatters.dart';
import '../../core/themes/app_colors.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/l10n_labels.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/settings_row.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/sns_style.dart';
import '../../core/ui/state_view.dart';
import '../../creator/widgets/creator_screen.dart';
import '../../settings/widgets/contact_dialog.dart';
import '../../share/widgets/share_link_screen.dart';
import '../view_models/creator_admin_providers.dart';
import '../view_models/creator_links_viewmodel.dart';
import '../view_models/creator_menu_viewmodel.dart';
import '../view_models/reach_viewmodel.dart';
import 'account_link_screen.dart';
import 'announce_image_screen.dart';
import 'event_manage_screen.dart';
import 'plan_screen.dart';
import 'post_manage_screen.dart';
import 'profile_edit_screen.dart';
import 'creator_links_screen.dart';
import 'reach_screen.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 発信者メニュー（画面定義書 2.2.2）。発信者向けの設定の入口。
/// 下部ナビの発信者のタブの本体（画面定義書 5.1.1）なので、戻るは置かない。
/// 発信者の下部ナビには設定の丸がないので、ヘッダーの右の歯車から、設定を開く（試作）。
class CreatorMenuScreen extends ConsumerWidget {
  const CreatorMenuScreen({
    super.key,
    required this.creatorId,
    this.onOpenSettings,
  });

  final String creatorId;

  /// ヘッダーの右の歯車を押したとき。null なら、歯車を出さない。
  final VoidCallback? onOpenSettings;

  Future<void> _contact(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(creatorMenuViewModelProvider(creatorId).notifier);
    final draft = await vm.contactDraft(
      subject: l10n.commonContactSubject,
      body: (userId, version, os) =>
          l10n.commonContactBody(userId, version, os),
      notSignedIn: l10n.commonContactNotSignedIn,
    );
    if (!context.mounted) return;
    await openContactMail(context, draft: draft, userId: vm.userId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(creatorMenuViewModelProvider(creatorId));
    void push(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        // 固定ビューアを出している間は、ヘッダーを中身と一緒にスクロールして隠す（画面定義書 5.1.2）。
        child: ViewerAwareHeader(
          header: TabHeader(
            title: l10n.commonCreatorMenu,
            actions: [
              if (onOpenSettings case final open?)
                HeaderIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: l10n.commonTabSettings,
                  onPressed: open,
                ),
            ],
          ),
          body: _body(context, ref, l10n, state, push),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<CreatorAdminData> state,
    void Function(Widget screen) push,
  ) {
    return state.when(
      skipLoadingOnRefresh: true,
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonLine(),
            SizedBox(height: 16),
            SkeletonLine(),
            SizedBox(height: 16),
            SkeletonLine(),
          ],
        ),
      ),
      error: (_, _) => StateView.error(
        onRetry: ref
            .read(creatorMenuViewModelProvider(creatorId).notifier)
            .retry,
      ),
      data: (s) => ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 16,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _ProfileCard(
              creator: s.creator,
              // カードを押すと、ファンが見るのと同じ自分の発信者ページを、発信者のタブのまま重ねて開く（2026-11-19 本人）。
              onOpenPage: () =>
                  Navigator.of(context).push(CreatorScreen.route(creatorId)),
              onEdit: () => push(ProfileEditScreen(creatorId: creatorId)),
              // 「追星に誘う」の画面（届ける・広める仕様書 4.3.6）。シェアの行から、カードの共有のボタンに移した（2026-11-19 本人）。
              onInvite: () =>
                  openShareLinkScreen(context, creatorId, asCreator: true),
              // 届いた数の要約（届ける・広める仕様書 4.2.2）。読めるまでは、見出しだけ。
              reachSummary: switch (ref.watch(
                reachOverviewProvider(creatorId),
              )) {
                AsyncData(:final value) => l10n.creatorAdminMenuReachSummary(
                  withCommas(value.delivered),
                ),
                _ => l10n.reachTitle,
              },
              onOpenReach: () => push(ReachScreen(creatorId: creatorId)),
            ),
          ),
          if (s.creator.suspended)
            SurfacePanel(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.creatorAdminSuspendedNotice,
                    style: TextStyle(
                      fontSize: 14,
                      height: 21 / 14,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TonalButton(
                    label: l10n.commonContact,
                    onPressed: () => _contact(context, ref),
                  ),
                ],
              ),
            ),
          // 自分のページと届いた数は、プロフィールカードにまとめた（2026-11-19 本人）。
          // 並びは、シェア・連携・コンテンツ・プラン（画面定義書（設定・発信者）2.2.2。2026-11-19 本人が決めた最終の形）。
          SectionLabel(l10n.creatorAdminMenuSectionShare),
          // 「追星に誘う」は、プロフィールカードの共有のボタンから開く（2026-11-19 本人）。
          // SNSリンク集を共有（リンク集。届ける・広める仕様書 4.6.1）。値は件数。読めていなければ出さない。
          // 名前を変え、「シェア」に移した（2026-11-19 本人）。
          SettingsRow(
            icon: Icons.format_list_bulleted,
            label: l10n.creatorAdminMenuLinks,
            value: switch (ref.watch(ownedCreatorLinksProvider(creatorId))) {
              AsyncData(:final value) => l10n.creatorAdminMenuLinkedCount(
                value.length,
              ),
              _ => null,
            },
            onTap: () => push(CreatorLinksScreen(creatorId: creatorId)),
          ),
          // 週間の告知画像（届ける・広める仕様書 4.4.1）。
          SettingsRow(
            icon: Icons.view_week_outlined,
            label: l10n.announceImageTitle,
            onTap: () => push(AnnounceImageScreen(creatorId: creatorId)),
          ),
          SectionLabel(l10n.creatorAdminMenuSectionLinks),
          // 「連携」は SNS だけ。
          // SNS の連携と、出す内容の切り替え（もとの「表示するコンテンツ」）をまとめた画面（2026-11-19 本人）。
          SettingsRow(
            icon: Icons.link,
            label: l10n.creatorAdminSnsTitle,
            // 小さな説明。つないだ数の代わりに出す（2026-11-19 本人）。
            value: l10n.creatorAdminMenuSnsNote,
            onTap: () => push(AccountLinkScreen(creatorId: creatorId)),
          ),
          // 「コンテンツ」は、投稿の管理・イベントの管理・予定のデフォルトの長さ。
          // 予定のデフォルトの長さは配信にも効くので、イベントの管理の中には入れず、ここに並べる（2026-11-19 本人）。
          SectionLabel(l10n.creatorAdminMenuSectionContent),
          SettingsRow(
            icon: Icons.article_outlined,
            label: l10n.creatorAdminPostManageTitle,
            onTap: () => push(PostManageScreen(creatorId: creatorId)),
          ),
          SettingsRow(
            icon: Icons.confirmation_number_outlined,
            label: l10n.creatorAdminMenuEventManage,
            onTap: () => push(EventManageScreen(creatorId: creatorId)),
          ),
          SectionLabel(l10n.creatorAdminPlanTitle),
          SettingsRow(
            icon: Icons.workspace_premium_outlined,
            label: l10n.creatorAdminPlanTitle,
            value: l10n.creatorPlan(s.creator.plan),
            onTap: () => push(PlanScreen(plan: s.creator.plan)),
          ),
        ],
      ),
    );
  }
}

/// 発信者メニューの一番上の、プロフィールカード（画面定義書（設定・発信者）2.2.2）。
/// 押すと自分の発信者ページ、右上の共有のボタンで「追星に誘う」、鉛筆でプロフィールの編集、下の要約で届いた数を開く（2026-11-19 本人）。
/// 共有と鉛筆のボタンは、カードの押せる所の上に重ねた別のボタンなので、押すとボタンの方だけが動く。
/// プランのチップの右に、連携した SNS（確認が済んだもの）のアイコンを並べる。
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.creator,
    required this.onOpenPage,
    required this.onEdit,
    required this.onInvite,
    required this.reachSummary,
    required this.onOpenReach,
  });

  final Creator creator;
  final VoidCallback onOpenPage;
  final VoidCallback onEdit;
  final VoidCallback onInvite;
  final String reachSummary;
  final VoidCallback onOpenReach;

  // 名前と ID の行の高さを決めて、ボタンを名前の行の真ん中にそろえる。
  static const _avatarSize = 60.0;
  static const _nameLine = 24.0;
  static const _nameGap = 2.0;
  static const _handleLine = 18.0;

  /// ボタン2つ（44×2）と右の余白の分。名前と ID は、この幅を空ける。
  static const _iconsReserve = 44.0 * 2 + 4 - 16;

  /// ボタンの上端。カードの上の余白 16 ＋ 文字の塊を写真の真ん中に置いたときの名前の行の真ん中 − ボタンの半分。
  static const _iconsTop =
      16 +
      (_avatarSize - (_nameLine + _nameGap + _handleLine)) / 2 +
      _nameLine / 2 -
      22;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // カードの押せる所（自分のページ）の上に、共有と鉛筆のボタンを重ねる。
          // ボタンはカードの右端にそろえ、名前の行の真ん中の高さに置く。見た目は名前の文字と同じ大きさ（18）、押せる範囲は 44 四方。
          // 名前と ID は、ボタンの幅を空けて「…」で切る（2026-11-19 本人）。
          Stack(
            children: [
              InkWell(
                key: const ValueKey('creator-menu-own-page'),
                onTap: onOpenPage,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AvatarImage(
                            url: creator.avatarUrl,
                            size: _avatarSize,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: _iconsReserve,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  OneLineText(
                                    creator.name,
                                    style: TextStyle(
                                      fontSize: 18,
                                      height: _nameLine / 18,
                                      fontWeight: FontWeight.w700,
                                      color: c.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: _nameGap),
                                  OneLineText(
                                    creator.handle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: _handleLine / 13,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          StatusChip(l10n.creatorPlan(creator.plan)),
                          if (creator.suspended) ...[
                            const SizedBox(width: 6),
                            StatusChip(l10n.commonSuspended, muted: true),
                          ],
                          // 連携した SNS（確認が済んだものだけ。追星に出すものと同じ）。
                          for (final service in SnsService.values)
                            if (creator.accounts.containsKey(service)) ...[
                              const SizedBox(width: 6),
                              Semantics(
                                label: l10n.sns(service),
                                // プランのチップと同じ高さ（上下の余白 3 + 文字 14）にそろえる。
                                child: PlatformIcon(service, size: 20),
                              ),
                            ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: _iconsTop,
                right: 4,
                child: Row(
                  children: [
                    _CardIconButton(
                      key: const ValueKey('creator-menu-invite'),
                      icon: Icons.ios_share,
                      tooltip: l10n.shareInviteTitle,
                      onPressed: onInvite,
                    ),
                    _CardIconButton(
                      key: const ValueKey('creator-menu-edit-profile'),
                      icon: Icons.edit_outlined,
                      tooltip: l10n.creatorAdminMenuProfileCardHint,
                      onPressed: onEdit,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 1, thickness: 1, color: c.divider),
          InkWell(
            key: const ValueKey('creator-menu-reach'),
            onTap: onOpenReach,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    size: 18,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OneLineText(
                      reachSummary,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: c.textTertiary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// プロフィールカードの名前の右の、小さなアイコンのボタン。見た目は名前の文字と同じ大きさ、押せる範囲は 44 四方。
class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    iconSize: 18,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    icon: Icon(icon, color: context.colors.textSecondary),
    onPressed: onPressed,
  );
}
