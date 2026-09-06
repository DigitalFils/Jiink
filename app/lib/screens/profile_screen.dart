import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/payments_service.dart';
import '../services/listing_filter.dart';
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
                  backgroundColor: S8llColors.limeSoft,
                  child: Text(
                    (profile?.displayName ?? '?').isEmpty
                        ? '?'
                        : (profile?.displayName ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      color: S8llColors.lime,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.displayName ?? '…',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
          // The prototype's stat row, built only from numbers the account
          // really has. It showed "Assets £2,840", a follower count and a
          // level; there is no wallet balance, no follow graph and no
          // levelling here, so the three real equivalents stand in: how
          // many of your listings are live right now, how many have sold,
          // and how many people are watching across all of them.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: S8llSpacing.lg),
              decoration: BoxDecoration(
                color: context.s8ll.surface,
                borderRadius: BorderRadius.circular(S8llRadius.md),
              ),
              child: Row(
                children: [
                  _Stat(
                    value: '${stillLive(myListings, now: DateTime.now()).length}',
                    label: 'Live now',
                  ),
                  _StatDivider(),
                  _Stat(
                    value: '${myListings.where((l) => l.status == ListingStatus.sold).length}',
                    label: 'Sold',
                  ),
                  _StatDivider(),
                  _Stat(
                    value: '${myListings.fold<int>(0, (sum, l) => sum + l.watcherCount)}',
                    label: 'Watching',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: S8llSpacing.md),
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

/// One figure in the profile's stat row. Value large in lime, caption
/// under it — the prototype's treatment, carrying a real count.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: S8llColors.lime,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.s8ll.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: context.s8ll.divider);
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
