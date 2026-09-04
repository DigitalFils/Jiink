import 'package:flutter/material.dart';

import '../theme.dart';

class CountdownBadge extends StatelessWidget {
  const CountdownBadge({super.key, required this.remaining});

  final Duration remaining;

  String get _label {
    if (remaining == Duration.zero) return 'Expired';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours >= 1) return '${hours}h left';
    return '${minutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final expiring = remaining.inMinutes <= 30 && remaining > Duration.zero;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: expiring ? Colors.redAccent : S8llColors.lime,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: expiring ? Colors.white : S8llColors.black,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
