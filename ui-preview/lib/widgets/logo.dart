import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class S8LLLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const S8LLLogo({
    super.key,
    this.size = 48,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'S8LL',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? AppTheme.accent,
        letterSpacing: -2,
        height: 1,
      ),
    );
  }
}

class S8LLLogoWithIcon extends StatelessWidget {
  final double size;

  const S8LLLogoWithIcon({
    super.key,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: AppTheme.accent,
          size: size * 0.9,
        ),
        const SizedBox(width: 6),
        Text(
          'S8LL',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}
