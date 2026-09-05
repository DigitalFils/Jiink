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
            return _placeholder(context, height, child: const CircularProgressIndicator());
          },
          errorBuilder: (context, error, stack) => _placeholder(context, height),
        ),
      );
    }
    return _placeholder(context, height);
  }

  Widget _placeholder(BuildContext context, double height, {Widget? child}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.s8ll.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.s8ll.divider),
      ),
      child: Center(
        child: child ??
            Icon(Icons.shopping_bag_outlined, size: 48, color: context.s8ll.textSecondary),
      ),
    );
  }
}
