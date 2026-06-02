import 'package:flutter/material.dart';
import 'package:frontend_evenout/core/theme/app_colors.dart';
import '../models/expense_participant.dart';

class ParticipantTile extends StatelessWidget {
  final ExpenseParticipant participant;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;
  final bool included;
  final bool canToggle;
  final VoidCallback? onToggle;
  final Widget trailing;
  final Widget avatar;

  const ParticipantTile({
    super.key,
    required this.participant,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.included,
    required this.canToggle,
    this.onToggle,
    required this.trailing,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: included ? 1 : 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (canToggle)
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  included
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: included ? AppColors.primary : subtextColor,
                  size: 22,
                ),
              ),
            if (canToggle) const SizedBox(width: 10),
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Text(participant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
