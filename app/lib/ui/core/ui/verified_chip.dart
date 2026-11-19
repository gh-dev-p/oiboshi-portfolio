import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../themes/app_colors.dart';
import 'app_buttons.dart';

/// 「確認済み」のチップ。
class VerifiedChip extends StatelessWidget {
  const VerifiedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return StatusChip(
      AppLocalizations.of(context)!.commonVerified,
      icon: Icons.verified,
      background: c.verifiedFill,
      foreground: c.verifiedText,
    );
  }
}
