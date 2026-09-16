import 'package:flutter/material.dart';

import '../theme.dart';

/// The wordmark, exactly as the v2 zip defines it.
///
/// Carried over unchanged, including the fixed -2 letter-spacing. An
/// earlier version here scaled the tracking with the font size, which is
/// arguably more correct typographically and is *not* what the design does
/// — at 28px the zip's mark is noticeably tighter than a proportional one.
/// Keeping v2's exact numbers matters more than the theory.
class S8LLLogo extends StatelessWidget {
  const S8LLLogo({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'S8LL',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? S8llColors.lime,
        letterSpacing: -2,
        height: 1,
      ),
    );
  }
}

/// The lockup: the flame mark beside a white wordmark. v2's, unchanged.
class S8LLLogoWithIcon extends StatelessWidget {
  const S8LLLogoWithIcon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department_rounded,
          color: S8llColors.lime,
          size: size * 0.9,
        ),
        const SizedBox(width: 6),
        Text(
          'S8LL',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size,
            fontWeight: FontWeight.w900,
            color: S8llColors.white,
            letterSpacing: -1.5,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// The app icon's mark on its own: the flame in a lime rounded square, the
/// same thing the splash animates in and the same thing the launcher icon
/// is generated from. One definition, so the icon on the home screen and
/// the icon in the app can't drift apart.
class S8LLMark extends StatelessWidget {
  const S8LLMark({
    super.key,
    this.size = 120,
    this.glow = true,
    this.radiusRatio = 32 / 120,
  });

  final double size;
  final bool glow;

  /// Corner radius as a fraction of [size]. v2's splash uses 32 at 120px.
  /// The launcher icon passes 0: Android masks the icon to the launcher's
  /// own shape, and pre-rounding it just leaves dead corners inside that
  /// mask.
  final double radiusRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: S8llColors.lime,
        borderRadius: BorderRadius.circular(size * radiusRatio),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: S8llColors.lime.withValues(alpha: 0.4),
                  blurRadius: size / 3,
                  spreadRadius: size / 24,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.local_fire_department_rounded,
        color: S8llColors.black,
        size: size * (64 / 120),
      ),
    );
  }
}

/// The wordmark with a screen name beside it — Drops, Chat, Profile.
///
/// The label is Flexible and scales down rather than pushing anything off
/// the edge, which is what an unconstrained Row here did at large
/// accessibility text sizes.
class S8llScreenHeading extends StatelessWidget {
  const S8llScreenHeading(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const S8LLLogo(size: 40),
        const SizedBox(width: 10),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: S8llColors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
