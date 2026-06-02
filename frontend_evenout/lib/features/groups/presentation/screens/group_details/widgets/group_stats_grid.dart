import 'package:flutter/material.dart';

class GroupStatsGrid extends StatelessWidget {
  final double totalGroupSpend;
  final double userBalance;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;

  const GroupStatsGrid({
    super.key,
    required this.totalGroupSpend,
    required this.userBalance,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Row(
        children: [
          // Total group spending
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spend',
                    style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${totalGroupSpend.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15.0),
          
          // User active split balance inside this group
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Share',
                    style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    userBalance > 0 
                        ? '+\$${userBalance.toStringAsFixed(2)}'
                        : userBalance < 0
                            ? '-\$${userBalance.abs().toStringAsFixed(2)}'
                            : '\$0.00',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: userBalance > 0 
                          ? const Color(0xFF2E7D32) 
                          : userBalance < 0
                              ? const Color(0xFFC62828)
                              : textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
