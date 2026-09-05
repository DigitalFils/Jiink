import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'countdown_badge.dart';
import 'listing_photo.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ListingPhoto(photoUrl: listing.photoUrl),
                  if (listing.status == ListingStatus.sold)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'SOLD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CountdownBadge(remaining: listing.remaining(DateTime.now())),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                listing.title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '£${listing.priceInPounds.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: S8llColors.lime,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${listing.sellerName} · ${listing.delivery.label}',
                    style: const TextStyle(color: S8llColors.grey, fontSize: 12),
                  ),
                ],
              ),
              if (listing.watcherCount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 14, color: S8llColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      listing.watcherCount == 1
                          ? '1 watching'
                          : '${listing.watcherCount} watching',
                      style: const TextStyle(color: S8llColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
