import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/countdown_badge.dart';
import '../widgets/listing_photo.dart';
import 'chat_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isMine = listing.seller.id == currentUser.id;
    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ListingPhoto(listing: listing, height: 320),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CountdownBadge(remaining: listing.remaining(DateTime.now())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '£${listing.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: S8llColors.lime,
                fontWeight: FontWeight.w800,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(listing.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (listing.description.isNotEmpty) Text(listing.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: S8llColors.grey),
                const SizedBox(width: 6),
                Text('${listing.seller.name} · ${listing.seller.city}',
                    style: const TextStyle(color: S8llColors.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: S8llColors.grey),
                const SizedBox(width: 6),
                Text(listing.delivery.label, style: const TextStyle(color: S8llColors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            if (isMine)
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().bumpListing(listing.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bumped back to the top of the feed')),
                  );
                },
                child: const Text('Bump listing'),
              )
            else
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ChatScreen(listing: listing)),
                ),
                child: const Text('Message seller'),
              ),
          ],
        ),
      ),
    );
  }
}
