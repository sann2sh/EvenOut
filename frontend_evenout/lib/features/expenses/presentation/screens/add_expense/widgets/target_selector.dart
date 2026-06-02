import 'package:flutter/material.dart';
import 'package:frontend_evenout/core/theme/app_colors.dart';
import 'package:frontend_evenout/features/user/presentation/providers/friends_provider.dart';

class TargetSelector extends StatelessWidget {
  final String mode;
  final String? groupId;
  final String? groupName;
  final Friend? friend;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;

  const TargetSelector({
    super.key,
    required this.mode,
    this.groupId,
    this.groupName,
    this.friend,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasTarget = mode == 'group' ? groupId != null : friend != null;
    final String title = mode == 'group'
        ? (groupName ?? 'Select a group')
        : (friend?.label ?? 'Select a friend');
    final String subtitle = mode == 'group'
        ? 'Group expense • Paid by you'
        : (friend == null ? 'Tap to choose' : 'Peer to peer • Paid by you');

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: hasTarget
                  ? AppColors.primary.withOpacity(0.4)
                  : (isDark ? Colors.white12 : Colors.grey.shade200),
              width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mode == 'group' ? Icons.groups_rounded : Icons.person_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('You & $title',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subtextColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: subtextColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
