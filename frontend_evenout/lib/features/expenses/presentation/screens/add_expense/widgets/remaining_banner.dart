import 'package:flutter/material.dart';
import 'package:frontend_evenout/core/theme/app_colors.dart';
import '../models/expense_participant.dart';

class RemainingBanner extends StatelessWidget {
  final String splitMode;
  final double amount;
  final List<ExpenseParticipant> parts;
  final Map<String, TextEditingController> exactCtrls;
  final Map<String, TextEditingController> pctCtrls;

  const RemainingBanner({
    super.key,
    required this.splitMode,
    required this.amount,
    required this.parts,
    required this.exactCtrls,
    required this.pctCtrls,
  });

  TextEditingController _inputCtrl(Map<String, TextEditingController> map, String id) {
    return map.putIfAbsent(id, () => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    if (splitMode == 'exact') {
      double sum = 0;
      for (final p in parts) {
        sum += double.tryParse(_inputCtrl(exactCtrls, p.id).text.trim()) ?? 0;
      }
      final left = amount - sum;
      final ok = left.abs() <= 0.01;
      return _bannerBox(
        ok
            ? 'All set — amounts add up to Rs ${amount.toStringAsFixed(2)}'
            : left > 0
                ? 'Rs ${left.toStringAsFixed(2)} left to assign'
                : 'Over by Rs ${(-left).toStringAsFixed(2)}',
        ok,
      );
    }
    if (splitMode == 'percentage') {
      double sum = 0;
      for (final p in parts) {
        sum += double.tryParse(_inputCtrl(pctCtrls, p.id).text.trim()) ?? 0;
      }
      final left = 100 - sum;
      final ok = left.abs() <= 0.01;
      return _bannerBox(
        ok
            ? 'All set — percentages total 100%'
            : left > 0
                ? '${left.toStringAsFixed(1)}% left to assign'
                : 'Over by ${(-left).toStringAsFixed(1)}%',
        ok,
      );
    }
    if (splitMode == 'equal' && parts.isNotEmpty) {
      final each = amount / parts.length;
      return _bannerBox(
          'Rs ${each.toStringAsFixed(2)} each • ${parts.length} people', true,
          neutral: true);
    }
    return const SizedBox.shrink();
  }

  Widget _bannerBox(String text, bool ok, {bool neutral = false}) {
    final color = neutral
        ? AppColors.primary
        : ok
            ? AppColors.settle
            : AppColors.owe;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(neutral ? Icons.info_outline_rounded : (ok ? Icons.check_circle_rounded : Icons.error_outline_rounded),
              size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}
