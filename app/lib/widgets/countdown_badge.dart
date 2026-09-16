import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

class CountdownBadge extends StatelessWidget {
  const CountdownBadge({super.key, required this.remaining});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final expiring = remaining.inMinutes <= 30 && remaining > Duration.zero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: expiring ? S8llColors.live : S8llColors.lime,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        remainingLabel(remaining),
        style: TextStyle(
          color: expiring ? Colors.white : S8llColors.black,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
