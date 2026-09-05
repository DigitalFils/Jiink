import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Shows a seller's aggregate rating, or "No ratings yet" once it's known
/// there are none. Pass null while the rating is still loading — reserves
/// layout space so nothing jumps once it resolves.
class SellerRatingBadge extends StatelessWidget {
  const SellerRatingBadge({super.key, required this.rating});

  final SellerRating? rating;

  @override
  Widget build(BuildContext context) {
    if (rating == null) {
      return const SizedBox(height: 16);
    }
    if (!rating!.hasRatings) {
      return const Text('No ratings yet', style: TextStyle(color: S8llColors.grey, fontSize: 12));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: S8llColors.lime, size: 16),
        const SizedBox(width: 4),
        Text(
          rating!.average.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(width: 4),
        Text(
          rating!.count == 1 ? '(1 review)' : '(${rating!.count} reviews)',
          style: const TextStyle(color: S8llColors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
