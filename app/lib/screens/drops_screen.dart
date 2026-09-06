import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/listing_filter.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/listing_photo.dart';
import '../widgets/logo.dart';
import 'capture_screen.dart';
import 'listing_detail_screen.dart';

/// Drops: the same live listings as Home, organised by *who* is selling
/// rather than by what's ending.
///
/// The row of circles along the top is one per seller with something live —
/// tap one to see only their drops. The banner underneath counts down the
/// single soonest-ending listing on the whole feed, because that's the one
/// piece of information that turns browsing into moving.
class DropsScreen extends StatefulWidget {
  const DropsScreen({super.key});

  @override
  State<DropsScreen> createState() => _DropsScreenState();
}

class _DropsScreenState extends State<DropsScreen> {
  late DateTime _now;
  Timer? _ticker;

  /// Null means "everyone". Tapping the selected seller again clears it.
  String? _sellerFilter;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final blocked = appState.profile?.blockedUserIds ?? const [];

    final live = stillLive(appState.listings, now: _now)
        .where((l) => !blocked.contains(l.sellerId))
        .toList()
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

    // Sold items stay in the list as proof things move, but they are not
    // what "N live" or the ending-soon banner are counting — a countdown on
    // something already gone is just wrong.
    final sellable = live.where((l) => l.status != ListingStatus.sold).toList();

    final sellers = _sellersOf(sellable);
    // A seller whose last listing just ended shouldn't stay selected with
    // an empty list underneath.
    final activeFilter = sellers.any((s) => s.id == _sellerFilter) ? _sellerFilter : null;
    final rows =
        activeFilter == null ? live : live.where((l) => l.sellerId == activeFilter).toList();

    return Scaffold(
      backgroundColor: S8llColors.black,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _DropsHeader()),
            if (sellers.isNotEmpty)
              SliverToBoxAdapter(
                child: _SellerStrip(
                  sellers: sellers,
                  selected: activeFilter,
                  onSelect: (id) => setState(
                    () => _sellerFilter = _sellerFilter == id ? null : id,
                  ),
                  onSell: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CaptureScreen()),
                  ),
                ),
              ),
            if (sellable.isNotEmpty)
              SliverToBoxAdapter(child: _EndingSoonBanner(listing: sellable.first, now: _now)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  activeFilter == null
                      ? 'All drops'
                      : '${sellers.firstWhere((s) => s.id == activeFilter).name}\'s drops',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: S8llColors.white,
                  ),
                ),
              ),
            ),
            if (rows.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _NoDrops(),
              )
            else
              SliverList.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) => _DropRow(
                  listing: rows[index],
                  now: _now,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listing: rows[index]),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: S8llBottomNavBar.clearance),
            ),
          ],
        ),
      ),
    );
  }

  /// One entry per seller with something live, ordered by whoever is
  /// ending soonest — [live] is already in that order, so first-seen wins.
  List<_Seller> _sellersOf(List<Listing> live) {
    final seen = <String, _Seller>{};
    for (final listing in live) {
      seen.putIfAbsent(
        listing.sellerId,
        () => _Seller(
          id: listing.sellerId,
          name: listing.sellerName,
          photoUrl: listing.photoUrl,
          count: 0,
        ),
      );
      seen[listing.sellerId] = seen[listing.sellerId]!.plusOne();
    }
    return seen.values.toList();
  }
}

class _Seller {
  const _Seller({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.count,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final int count;

  _Seller plusOne() => _Seller(id: id, name: name, photoUrl: photoUrl, count: count + 1);
}

class _DropsHeader extends StatelessWidget {
  const _DropsHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: S8llScreenHeading('Drops'),
    );
  }
}

/// Sellers with something live, as tappable circles. The lime ring is not
/// decoration — it means this seller is live right now, and the count in
/// the corner is how many things they have running.
class _SellerStrip extends StatelessWidget {
  const _SellerStrip({
    required this.sellers,
    required this.selected,
    required this.onSelect,
    required this.onSell,
  });

  final List<_Seller> sellers;
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sellers.length + 1,
        itemBuilder: (context, index) {
          if (index == sellers.length) return _AddYourDrop(onTap: onSell);
          final seller = sellers[index];
          return _SellerCircle(
            seller: seller,
            selected: seller.id == selected,
            onTap: () => onSelect(seller.id),
          );
        },
      ),
    );
  }
}

class _SellerCircle extends StatelessWidget {
  const _SellerCircle({
    required this.seller,
    required this.selected,
    required this.onTap,
  });

  final _Seller seller;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? S8llColors.white : S8llColors.lime,
                  width: 2.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: ListingPhoto(
                    photoUrl: seller.photoUrl,
                    height: null,
                    borderRadius: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                seller.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? S8llColors.lime : S8llColors.white,
                ),
              ),
            ),
            Text(
              '${seller.count} live',
              style: const TextStyle(fontSize: 10, color: S8llColors.greyLow),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddYourDrop extends StatelessWidget {
  const _AddYourDrop({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: S8llColors.divider, width: 2),
              ),
              child: const Icon(Icons.add, color: S8llColors.grey, size: 28),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your drop',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: S8llColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The soonest-ending listing on the feed, with a real second-by-second
/// countdown. Tapping it goes straight there — the banner is the shortcut,
/// not an advert for one.
class _EndingSoonBanner extends StatelessWidget {
  const _EndingSoonBanner({required this.listing, required this.now});

  final Listing listing;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final remaining = listing.remaining(now);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: S8llColors.lime,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Expanded + scaleDown: a long title at this weight is wider
              // than the banner on a normal phone, and left rigid it shoves
              // the countdown off the right edge — the one part of a
              // live-drop banner that has to stay readable.
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: S8llColors.live, size: 12),
                    const SizedBox(width: 10),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ENDING SOON · ${listing.title.toUpperCase()}',
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: S8llColors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: S8llColors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: S8llColors.black.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _clock(remaining),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: S8llColors.black,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tabular figures and fixed width, so a ticking clock doesn't make the
  /// banner shuffle sideways once a second.
  static String _clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }
}

/// A full-width row: photo, then what it is, what it costs and how long is
/// left. Wider than the Home grid's cards on purpose — this screen is for
/// reading down a list, not scanning a wall.
class _DropRow extends StatelessWidget {
  const _DropRow({required this.listing, required this.now, required this.onTap});

  final Listing listing;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = listing.remaining(now);
    final sold = listing.status == ListingStatus.sold;
    final urgent = !sold && remaining.inHours < 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GestureDetector(
        onTap: onTap,
        // IntrinsicHeight rather than either of the two obvious things.
        // CrossAxisAlignment.stretch alone asks children to fill the cross
        // axis, which inside a sliver is unbounded — the row demanded
        // infinite height and silently rendered nothing. Pinning it to a
        // flat 120 fixed that but clipped the text by a few pixels the
        // moment a title wrapped to two lines. This lets the content set
        // the height, with 120 as a floor so short rows still look like
        // rows, and the photo stretches to whatever that comes to.
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: S8llColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: S8llColors.divider, width: 0.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ListingPhoto(
                          photoUrl: listing.photoUrl,
                          height: null,
                          borderRadius: 0,
                        ),
                        if (sold) Container(color: Colors.black.withValues(alpha: 0.55)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: S8llColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '£${listing.priceInPounds.toStringAsFixed(0)}',
                              maxLines: 1,
                              style: const TextStyle(
                                color: S8llColors.lime,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // A sold item is still worth showing — it's the
                              // proof things move here — but showing it with a
                              // countdown says it's still buyable, which it
                              // isn't.
                              Icon(
                                sold ? Icons.check_circle : Icons.schedule,
                                size: 13,
                                color: sold
                                    ? S8llColors.grey
                                    : urgent
                                        ? S8llColors.live
                                        : S8llColors.greyLow,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                sold ? 'Sold' : remainingLabel(remaining),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sold
                                      ? S8llColors.grey
                                      : urgent
                                          ? S8llColors.live
                                          : S8llColors.greyLow,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  listing.sellerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: S8llColors.greyLow),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoDrops extends StatelessWidget {
  const _NoDrops();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: S8llSpacing.xl, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_fire_department_outlined, size: 48, color: S8llColors.greyLow),
            SizedBox(height: S8llSpacing.md),
            Text(
              'No drops running',
              style: TextStyle(
                color: S8llColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: S8llSpacing.sm),
            Text(
              'When someone lists, it shows up here for eight hours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: S8llColors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
