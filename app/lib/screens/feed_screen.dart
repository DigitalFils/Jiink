import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listings = context.watch<AppState>().listings;
    return Scaffold(
      appBar: AppBar(title: const Text('S8LL')),
      body: listings.isEmpty
          ? const Center(child: Text('Nothing live right now.'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                final listing = listings[index];
                return ListingCard(
                  listing: listing,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
                  ),
                );
              },
            ),
    );
  }
}
