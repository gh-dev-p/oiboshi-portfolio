import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/themes/app_colors.dart';

/// 設定の「発信者として登録する」のカード（画面定義書 2.1.1）。大事な入口なので、行ではなくカードにする。
/// 紺の薄い塗りに、紺の丸いアイコン。タイトルの行の右に、青い星のキャラクター（飾り。読み上げない）を置く。
/// [enabled] が偽（アカウント作成の前）なら、グレーにして押せなくし、キャラクターも薄くして、
/// 「先にアカウントを作成してください」を添える。
class RegisterCreatorCard extends StatelessWidget {
  const RegisterCreatorCard({
    super.key,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  /// 青い星のキャラクターの絵（背景が透明。app/assets/characters/）。
  static const blueStarCharacter = 'assets/characters/blue.png';

  /// キャラクターを置く枠の高さ。カードの高さは、この枠で決まる（キャラクターを小さくしても変えない）。
  static const characterSlotHeight = 52.0;

  /// 左の＋の円の大きさ。
  static const markSize = 40.0;

  /// キャラクターの高さ。左の＋の円と同じ高さにする（2026-11-10 本人）。枠の中で、上下の真ん中に置く
  /// （円も行の上下の真ん中にあるので、縦の中心がそろう）。
  static const characterHeight = markSize;

  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = context.colors;
    final fill = enabled ? c.accentNavyFill : c.surface;
    final mark = enabled ? c.accentNavy : c.disabled;
    final titleColor = enabled ? c.textPrimary : c.textTertiary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
            child: Row(
              children: [
                Container(
                  width: markSize,
                  height: markSize,
                  decoration: BoxDecoration(
                    color: mark,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 22, color: c.onAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      if (!enabled) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.settingsAccountRequired,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 飾りなので、読み上げない。グレーのときは、色は変えずに薄くする。
                ExcludeSemantics(
                  child: Opacity(
                    opacity: enabled ? 1 : 0.4,
                    child: SizedBox(
                      height: characterSlotHeight,
                      child: Center(
                        child: Image.asset(
                          blueStarCharacter,
                          height: characterHeight,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 22, color: mark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
