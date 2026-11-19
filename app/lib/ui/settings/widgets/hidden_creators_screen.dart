import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/creator.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_text_styles.dart';
import '../../core/ui/app_buttons.dart';
import '../../core/ui/app_snack_bar.dart';
import '../../core/ui/async_state.dart';
import '../../core/ui/oshi_avatar.dart';
import '../../core/ui/screen_app_bar.dart';
import '../../core/ui/skeleton.dart';
import '../../core/ui/state_view.dart';
import '../../core/view_models/loading_overlay_provider.dart';
import '../view_models/hidden_creators_viewmodel.dart';
import '../../core/ui/one_line_text.dart';
import '../../core/ui/viewer_aware_header.dart';

/// 表示しない発信者（画面定義書（設定・発信者向け）2.1.10）。表示しないにした発信者を一覧し、元に戻す。
class HiddenCreatorsScreen extends ConsumerWidget {
  const HiddenCreatorsScreen({super.key});

  Future<void> _unhide(
    BuildContext context,
    WidgetRef ref,
    Creator creator,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final vm = ref.read(hiddenCreatorsViewModelProvider.notifier);
    final ok = await ref
        .read(loadingOverlayProvider.notifier)
        .run(() => vm.unhide(creator.id));
    if (context.mounted) {
      showAppSnackBar(
        context,
        ok
            ? l10n.settingsHiddenCreatorRestored
            : l10n.settingsHiddenCreatorRestoreFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(hiddenCreatorsViewModelProvider);
    final vm = ref.read(hiddenCreatorsViewModelProvider.notifier);
    return HeaderScaffold(
      appBar: ScreenAppBar(title: l10n.settingsHiddenCreators),
      body: asyncBody(
        state,
        data: (creators) => creators.isEmpty
            ? StateView(
                icon: Icons.visibility_off_outlined,
                title: l10n.settingsHiddenCreatorsEmpty,
                message: l10n.settingsHiddenCreatorsDescription,
              )
            : ListView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 16,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      l10n.settingsHiddenCreatorsDescription,
                      style: context.textStyles.note,
                    ),
                  ),
                  for (final creator in creators)
                    _HiddenCreatorRow(
                      key: ValueKey('hidden-${creator.id}'),
                      creator: creator,
                      onUnhide: () => _unhide(context, ref, creator),
                    ),
                ],
              ),
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [SkeletonLine(), SizedBox(height: 16), SkeletonLine()],
          ),
        ),
        error: () => StateView.error(onRetry: vm.retry),
      ),
    );
  }
}

/// 表示しない発信者の行（アイコン、名前、ID、「表示する」）。
class _HiddenCreatorRow extends StatelessWidget {
  const _HiddenCreatorRow({
    super.key,
    required this.creator,
    required this.onUnhide,
  });

  final Creator creator;
  final VoidCallback onUnhide;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AvatarImage(url: creator.avatarUrl, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OneLineText(
                  creator.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                Text(creator.handle, style: context.textStyles.note),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppTextButton(
            label: AppLocalizations.of(context)!.settingsHiddenCreatorShow,
            onPressed: onUnhide,
          ),
        ],
      ),
    );
  }
}
