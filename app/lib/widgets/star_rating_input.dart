import 'package:flutter/material.dart';

import '../theme.dart';

/// Five tappable stars for leaving a rating. [value] is 0-5 (0 = none
/// picked yet).
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return IconButton(
          onPressed: () => onChanged(starValue),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          visualDensity: VisualDensity.compact,
          icon: Icon(
            starValue <= value ? Icons.star : Icons.star_border,
            color: S8llColors.lime,
            size: 28,
          ),
        );
      }),
    );
  }
}
