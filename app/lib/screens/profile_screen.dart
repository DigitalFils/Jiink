import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/payments_service.dart';
import '../services/reviews_repository.dart';
import '../state/app_state.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/listing_card.dart';
import '../widgets/seller_rating_badge.dart';
import 'listing_detail_screen.dart';
import 'payouts_setup_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  SellerRating? _rating;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AppState>().uid;
    context.read<ReviewsRepository>().sellerRating(uid).then((rating) {
      if (mounted) setState(() => _rating = rating);
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final myListings = appState.myListings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: context.s8ll.surfaceHigh,
                  child: const Icon(Icons.person, color: S8llColors.lime, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? '…',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(profile?.city ?? '', style: TextStyle(color: context.s8ll.textSecondary)),
                      const SizedBox(height: 4),
                      SellerRatingBadge(rating: _rating),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _PayoutStatusCard(payoutsEnabled: profile?.payoutsEnabled ?? false),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_outlined)),
              ],
              selected: {context.watch<ThemeController>().mode},
              onSelectionChanged: (selection) =>
                  context.read<ThemeController>().setMode(selection.first),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Your listings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (myListings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nothing listed yet — tap the camera to snap your first item.',
                  style: TextStyle(color: context.s8ll.textSecondary)),
            )
          else
            for (final listing in myListings)
              ListingCard(
                listing: listing,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
                ),
              ),
        ],
      ),
    );
  }
}

class _PayoutStatusCard extends StatelessWidget {
  const _PayoutStatusCard({required this.payoutsEnabled});

  final bool payoutsEnabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          payoutsEnabled ? Icons.check_circle : Icons.account_balance_outlined,
          color: payoutsEnabled ? S8llColors.lime : context.s8ll.textSecondary,
        ),
        title: Text(payoutsEnabled ? 'Payouts set up' : 'Payouts not set up'),
        subtitle: Text(
          payoutsEnabled
              ? "You're ready to sell shippable items in the app."
              : 'Needed before buyers can pay in-app for anything but meet-ups.',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: payoutsEnabled
            ? null
            : TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PayoutsSetupScreen(paymentsService: context.read<PaymentsService>()),
                  ),
                ),
                child: const Text('Set up'),
              ),
      ),
    );
  }
}
