import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';

/// Shows the listing's captured photo, or a placeholder for seeded/mock
/// listings that don't have one.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({super.key, required this.listing, this.height = 220});

  final Listing listing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final file = listing.photoFile;
    if (file != null && file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(file, height: height, width: double.infinity, fit: BoxFit.cover),
      );
    }
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: S8llColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, size: 48, color: S8llColors.grey),
      ),
    );
  }
}
