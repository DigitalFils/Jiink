import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback? onActionTap;

  const FeedCard({
    super.key,
    required this.item,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(item.sellerAvatar),
                backgroundColor: AppTheme.surface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.seller,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (item.isVerified)
                          const Icon(Icons.verified, color: AppTheme.accent, size: 16),
                      ],
                    ),
                    Text(
                      '${item.timeAgo} • ${item.isVerified ? "verified" : "user"}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.action == 'Buy Now' ? 'Buy now \$${item.price.toStringAsFixed(0)}' : 'Ask \$${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _buildStats(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 160,
                      child: item.action == 'Buy Now'
                          ? ElevatedButton(
                              onPressed: onActionTap,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(item.action),
                            )
                          : OutlinedButton(
                              onPressed: onActionTap,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(item.action),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 120,
                  height: 100,
                  child: Image.network(
                    item.images.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppTheme.surface);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildStats() {
    final parts = <String>[];
    if (item.bids != null) parts.add('${item.bids} bids');
    if (item.watching != null) parts.add('${item.watching} watching');
    if (item.ordersToday != null) parts.add('${item.ordersToday} orders today');
    parts.add('Condition: ${item.condition}');
    return parts.join(' • ');
  }
}
