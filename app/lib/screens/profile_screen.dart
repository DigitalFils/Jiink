import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/listing_filter.dart';
import '../services/payments_service.dart';
import '../services/reviews_repository.dart';
import '../state/app_state.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/drop_card.dart';
import '../widgets/logo.dart';
import '../widgets/seller_rating_badge.dart';
import 'listing_detail_screen.dart';
import 'payouts_setup_screen.dart';

/// Your side of the marketplace: who you are to buyers, whether you can
/// actually be paid, and everything you have listed.
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
    final now = DateTime.now();
    // Not expired *and* not sold — the same definition of "live" the feed
    // pill uses, so a seller's own count agrees with what buyers see.
    final live = stillLive(myListings, now: now)
        .where((l) => l.status != ListingStatus.sold)
        .toList();

    return Scaffold(
      backgroundColor: S8llColors.black,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: S8llBottomNavBar.clearance),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Expanded, so the heading takes the space left over by
                  // the sign-out button instead of sizing itself first and
                  // pushing the button off the edge.
                  const Expanded(child: S8llScreenHeading('Profile')),
                  IconButton(
                    icon: const Icon(Icons.logout, color: S8llColors.grey),
                    tooltip: 'Sign out',
                    onPressed: () => context.read<AuthService>().signOut(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: S8llColors.limeSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initial(profile?.displayName),
                      style: const TextStyle(
                        color: S8llColors.lime,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: S8llColors.white,
                          ),
                        ),
                        if ((profile?.city ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: S8llColors.greyLow),
                              const SizedBox(width: 4),
                              Text(
                                profile!.city,
                                style: const TextStyle(color: S8llColors.greyLow, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        SellerRatingBadge(rating: _rating),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: S8llSpacing.lg),
            // Real counts only. There is no wallet balance, no follower
            // graph and no seller "level" in this app, so the three numbers
            // an account genuinely has stand in their place.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: S8llColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: S8llColors.divider, width: 0.5),
                ),
                child: Row(
                  children: [
                    _Stat(value: '${live.length}', label: 'Live now'),
                    const _StatDivider(),
                    _Stat(
                      value: '${myListings.where((l) => l.status == ListingStatus.sold).length}',
                      label: 'Sold',
                    ),
                    const _StatDivider(),
                    _Stat(
                      value: '${myListings.fold<int>(0, (sum, l) => sum + l.watcherCount)}',
                      label: 'Watchers',
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
            const _SectionHeading('Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined)),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined)),
                  ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Auto'),
                      icon: Icon(Icons.brightness_auto_outlined)),
                ],
                selected: {context.watch<ThemeController>().mode},
                onSelectionChanged: (selection) =>
                    context.read<ThemeController>().setMode(selection.first),
              ),
            ),
            _SectionHeading('Your listings', trailing: '${myListings.length}'),
            if (myListings.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Nothing listed yet — tap the lime button to snap your first item.',
                  style: TextStyle(color: S8llColors.grey, fontSize: 13),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: myListings.length,
                itemBuilder: (context, index) => DropCard(
                  listing: myListings[index],
                  now: now,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listing: myListings[index]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _initial(String? name) {
    final trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.title, {this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: S8llColors.white,
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(color: S8llColors.greyLow, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

/// One figure in the stat row — value large in lime, caption under it.
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
              fontSize: 24,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12, color: S8llColors.grey)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: S8llColors.divider);
  }
}

class _PayoutStatusCard extends StatelessWidget {
  const _PayoutStatusCard({required this.payoutsEnabled});

  final bool payoutsEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: S8llColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: payoutsEnabled ? S8llColors.divider : S8llColors.lime,
          width: payoutsEnabled ? 0.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            payoutsEnabled ? Icons.check_circle : Icons.account_balance_outlined,
            color: payoutsEnabled ? S8llColors.lime : S8llColors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payoutsEnabled ? 'Payouts set up' : 'Payouts not set up',
                  style: const TextStyle(
                    color: S8llColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payoutsEnabled
                      ? "You're ready to sell shippable items in the app."
                      : 'Needed before buyers can pay in-app for anything but meet-ups.',
                  style: const TextStyle(color: S8llColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!payoutsEnabled)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PayoutsSetupScreen(paymentsService: context.read<PaymentsService>()),
                ),
              ),
              child: const Text('Set up'),
            ),
        ],
      ),
    );
  }
}
