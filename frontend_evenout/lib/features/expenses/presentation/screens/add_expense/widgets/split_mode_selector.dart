import 'package:flutter/material.dart';
import 'package:frontend_evenout/core/theme/app_colors.dart';

class SplitModeSelector extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;

  const SplitModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
  });

  static const _splitOptions = [
    ('equal', 'Equally', Icons.drag_handle_rounded),
    ('percentage', 'Percent', Icons.percent_rounded),
    ('exact', 'Exact', Icons.tune_rounded),
    ('itemized', 'Items', Icons.receipt_long_rounded),
    ('chaos_roulette', 'Chaos', Icons.casino_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final opt in _splitOptions) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onModeChanged(opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: currentMode == opt.$1 ? AppColors.primary : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: currentMode == opt.$1
                          ? AppColors.primary
                          : (isDark ? Colors.white12 : Colors.grey.shade200)),
                ),
                child: Column(
                  children: [
                    Icon(opt.$3,
                        size: 20,
                        color: currentMode == opt.$1 ? Colors.white : subtextColor),
                    const SizedBox(height: 4),
                    Text(opt.$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: currentMode == opt.$1
                                ? Colors.white
                                : subtextColor)),
                  ],
                ),
              ),
            ),
          ),
          if (opt != _splitOptions.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
