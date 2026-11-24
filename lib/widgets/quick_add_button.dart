import 'package:flutter/material.dart';

class QuickAddButton extends StatelessWidget {
  final int amount;
  final VoidCallback onTap;
  const QuickAddButton({super.key, required this.amount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.water_drop, size: 18),
            const SizedBox(height: 2),
            Text('+$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}