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
                  ListingPhoto(listing: listing),
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
                    '£${listing.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: S8llColors.lime,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '${listing.seller.name} · ${listing.delivery.label}',
                    style: const TextStyle(color: S8llColors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
