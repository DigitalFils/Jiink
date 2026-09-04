import 'package:flutter/material.dart';

import '../theme.dart';

/// Shows a listing's photo from its Storage download URL, or a placeholder
/// when it doesn't have one.
class ListingPhoto extends StatelessWidget {
  const ListingPhoto({super.key, required this.photoUrl, this.height = 220});

  final String? photoUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(height, child: const CircularProgressIndicator());
          },
          errorBuilder: (context, error, stack) => _placeholder(height),
        ),
      );
    }
    return _placeholder(height);
  }

  Widget _placeholder(double height, {Widget? child}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: S8llColors.charcoal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Center(
        child: child ??
            const Icon(Icons.shopping_bag_outlined, size: 48, color: S8llColors.grey),
      ),
    );
  }
}
