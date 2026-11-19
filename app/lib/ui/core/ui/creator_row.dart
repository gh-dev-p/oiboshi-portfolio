import 'package:flutter/material.dart';

import '../../../domain/models/creator.dart';
import '../../../domain/models/oshi.dart';
import '../themes/app_colors.dart';
import '../themes/app_text_styles.dart';
import 'follow_button.dart';
import 'oshi_avatar.dart';
import 'skeleton.dart';
import 'one_line_text.dart';

/// 発信者の行（アイコン、名前、ひとこと、フォロー／フォロー中のボタン）。推しを選ぶ・推しを探すで使う。
class CreatorRow extends StatelessWidget {
  const CreatorRow({
    super.key,
    required this.creator,
    required this.following,
    required this.now,
    required this.onFollow,
    this.onTap,
    this.avatarSize = 52,
  });

  final Creator creator;
  final bool following;
  final DateTime now;
  final VoidCallback onFollow;
  final VoidCallback? onTap;
  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final live = creator.liveAt(now) != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            OshiAvatar(
              avatarUrl: creator.avatarUrl,
              size: avatarSize,
              ring: live ? OshiRing.live : null,
              showLiveLabel: false,
            ),
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
                  if (creator.bio.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    OneLineText(
                      creator.bio.split('\n').first,
                      style: context.textStyles.note,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            FollowButton(following: following, onPressed: onFollow),
          ],
        ),
      ),
    );
  }
}

/// 発信者の一覧のスケルトン。
class CreatorListSkeleton extends StatelessWidget {
  const CreatorListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 6; i++)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SkeletonBox(width: 52, height: 52, circle: true),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 120),
                      SizedBox(height: 8),
                      SkeletonLine(width: 180, height: 10),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                SkeletonBox(width: 84, height: 30),
              ],
            ),
          ),
      ],
    );
  }
}
