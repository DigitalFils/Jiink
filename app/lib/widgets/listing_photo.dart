import 'package:flutter/material.dart';

import '../theme.dart';

/// Shows a listing's photo from its Storage download URL, or a placeholder
/// when it doesn't have one.
///
/// [height] null means "take whatever the parent gives you" — which is
/// what the feed grid needs, where the card sizes the photo rather than
/// the other way round.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({
    super.key,
    required this.photoUrl,
    this.height = 220,
    this.borderRadius = 16,
  });

  final String? photoUrl;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url == null || url.isEmpty) return _placeholder(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          // A spinner on a grid of loading photos is visual noise; a flat
          // surface in the card's own colour reads as the photo arriving.
          return _placeholder(context, icon: null);
        },
        errorBuilder: (context, error, stack) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context, {IconData? icon = Icons.shopping_bag_outlined}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: S8llColors.charcoalHigh,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: icon == null
          ? null
          : Icon(icon, size: 40, color: S8llColors.greyLow),
    );
  }
}
