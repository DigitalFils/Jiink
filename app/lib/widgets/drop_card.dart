import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import 'listing_photo.dart';

/// One listing in the feed grid.
///
/// Photo, a countdown pill, the title, then the price loud and lime, then
/// where it is. The price is the second thing you read after the photo,
/// which is why it is 32px and not tucked into a corner — on a feed of
/// things that disappear in a few hours, "how much" and "how long" are the
/// only two questions worth answering before the tap.
///
/// Every value here is real: [listing] comes from Firestore, and
/// [remaining] is recomputed by the screen's ticker rather than baked in
/// at build time, so the pill counts down while you look at it.
class DropCard extends StatelessWidget {
  const DropCard({
    super.key,
    required this.listing,
    required this.now,
    required this.onTap,
  });

  final Listing listing;

  /// Passed down rather than read from the clock here so that one ticker
  /// on the screen drives every card in step — 20 cards each holding
  /// their own Timer is 20 rebuild storms instead of one.
  final DateTime now;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sold = listing.status == ListingStatus.sold;
    final expired = listing.isExpired(now);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: S8llColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: S8llColors.divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded, not a fixed AspectRatio: the grid cell height is
            // fixed, so a square photo plus the text block came to more
            // than the cell could hold and the overflow sliced the price in
            // half. Letting the photo absorb the slack means the text
            // always fits — including when a two-line title or a larger
            // system text size makes the block taller.
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ListingPhoto(photoUrl: listing.photoUrl, height: null, borderRadius: 0),
                  if (sold)
                    Container(color: Colors.black.withValues(alpha: 0.55)),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _StatusPill(
                      listing: listing,
                      now: now,
                      sold: sold,
                      expired: expired,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: S8llColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // scaleDown so the price can never be the thing that
                  // overflows — a four-figure item or a bumped-up system
                  // text size shrinks the number instead of clipping it.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '£${listing.priceInPounds.toStringAsFixed(0)}',
                      maxLines: 1,
                      style: const TextStyle(
                        color: S8llColors.lime,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MetaRow(listing: listing),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The countdown pill, or what replaced it. Lime while there's time, red
/// under the hour because that's when it starts mattering, and charcoal
/// once it's over — a sold item shouldn't wear the same badge as a live one.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.listing,
    required this.now,
    required this.sold,
    required this.expired,
  });

  final Listing listing;
  final DateTime now;
  final bool sold;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = _appearance();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (String, Color, Color) _appearance() {
    if (sold) return ('SOLD', S8llColors.charcoalHigh, S8llColors.white);
    if (expired) return ('Ended', S8llColors.charcoalHigh, S8llColors.grey);
    final remaining = listing.remaining(now);
    final label = remainingLabel(remaining);
    // Under the hour it goes red: that's the point where "later" stops
    // being an option.
    if (remaining.inHours >= 1) return (label, S8llColors.lime, S8llColors.black);
    return (label, S8llColors.live, S8llColors.white);
  }
}

/// Where it is and who else is circling it. Watchers only show once there
/// is at least one — "0 watching" is worse than silence.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final watchers = listing.watcherCount;
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: S8llColors.greyLow, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            listing.sellerCity.isEmpty ? listing.sellerName : listing.sellerCity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: S8llColors.greyLow, fontSize: 12),
          ),
        ),
        if (watchers > 0) ...[
          const Icon(Icons.visibility_outlined, color: S8llColors.grey, size: 13),
          const SizedBox(width: 3),
          Text(
            '$watchers',
            style: const TextStyle(
              color: S8llColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
