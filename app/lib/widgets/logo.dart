import 'package:flutter/material.dart';

import '../theme.dart';

/// The wordmark. Heavy weight, tight tracking, lime — it carries the top
/// of the feed on its own, which is why it's set this large there.
class S8llLogo extends StatelessWidget {
  const S8llLogo({super.key, this.size = 48, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      'S8LL',
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? S8llColors.lime,
        letterSpacing: size * -0.04,
        height: 1,
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
        const S8llLogo(size: 40),
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
