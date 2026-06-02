import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color cardColor;
  final Color textColor;
  final Color subtextColor;

  const AmountField({
    super.key,
    required this.controller,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text('Rs',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: subtextColor)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: TextStyle(
                  fontSize: 30, fontWeight: FontWeight.bold, color: textColor),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '0.00',
                hintStyle: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: subtextColor.withOpacity(0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
