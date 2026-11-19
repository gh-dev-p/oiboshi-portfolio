import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

import '../themes/app_colors.dart';

/// フォロー／フォロー中のボタン（画面定義書 5.1.5）。推しリスト、推しを探す、推しを選ぶ、発信者ページで同じ見え方。
class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.following,
    required this.onPressed,
    this.withCheck = false,
  });

  final bool following;
  final VoidCallback? onPressed;

  /// 発信者ページでは、「フォロー中」にチェックのアイコンを添える。
  final bool withCheck;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = following ? c.textPrimary : c.onPrimary;
    return Material(
      color: following ? c.tonal : c.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: withCheck
              ? const EdgeInsets.fromLTRB(10, 6, 12, 6)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (withCheck) ...[
                Icon(following ? Icons.check : Icons.add, size: 16, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                following
                    ? AppLocalizations.of(context)!.commonFollowing
                    : AppLocalizations.of(context)!.commonFollow,
                style: TextStyle(
                  fontSize: withCheck ? 12 : 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: withCheck ? 16 / 12 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
