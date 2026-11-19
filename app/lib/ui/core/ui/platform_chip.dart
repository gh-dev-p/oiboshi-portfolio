import 'package:flutter/material.dart';

import '../../../domain/models/sns_service.dart';
import '../../../l10n/app_localizations.dart';
import '../themes/app_colors.dart';
import 'l10n_labels.dart';
import 'sns_style.dart';

/// プラットフォームのチップ（選んだものは塗り、選んでいないものは枠線）。
class PlatformChip extends StatelessWidget {
  const PlatformChip({
    super.key,
    required this.service,
    required this.selected,
    required this.onTap,
  });

  final SnsService? service;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
        decoration: BoxDecoration(
          color: selected ? c.primary : (dark ? c.surface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: selected ? null : Border.all(color: c.disabled),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 選んだチップは主色の塗り（ライトは黒、ダークは白）なので、X のロゴの白黒を塗りに合わせる。
            PlatformIcon(service, size: 18, onDark: selected ? !dark : null),
            const SizedBox(width: 6),
            Text(
              service == null ? l10n.commonNoService : l10n.sns(service!),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? c.onPrimary : c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
