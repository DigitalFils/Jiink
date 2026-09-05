import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/payments_service.dart';
import '../services/reviews_repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/countdown_badge.dart';
import '../widgets/listing_photo.dart';
import '../widgets/seller_rating_badge.dart';
import '../widgets/star_rating_input.dart';
import 'chat_screen.dart';
import 'payouts_setup_screen.dart';

class ListingDetailScreen extends StatefulWidget {
  const ListingDetailScreen({super.key, required this.listing});

  final Listing listing;

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _buying = false;
  late bool _watching;
  late int _watcherCount;

  SellerRating? _sellerRating;
  PurchaseOrder? _myOrder;
  Review? _existingReview;
  StreamSubscription<Review?>? _reviewSub;
  int _draftRating = 0;
  bool _submittingReview = false;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final uid = context.read<AppState>().uid;
    _watching = widget.listing.isWatchedBy(uid);
    _watcherCount = widget.listing.watcherCount;

    final reviews = context.read<ReviewsRepository>();
    reviews.sellerRating(widget.listing.sellerId).then((rating) {
      if (mounted) setState(() => _sellerRating = rating);
    });

    final isSold = widget.listing.status == ListingStatus.sold;
    final isMine = widget.listing.sellerId == uid;
    if (isSold && !isMine) {
      reviews
          .orderForPurchase(buyerId: uid, listingId: widget.listing.id)
          .then((order) {
        if (!mounted || order == null) return;
        setState(() => _myOrder = order);
        _reviewSub = reviews.reviewForListing(widget.listing.id).listen((review) {
          if (mounted) setState(() => _existingReview = review);
        });
      });
    }
  }

  @override
  void dispose() {
    _reviewSub?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final order = _myOrder;
    if (order == null || _draftRating == 0) return;
    setState(() => _submittingReview = true);
    try {
      await context.read<ReviewsRepository>().leaveReview(
            listingId: widget.listing.id,
            sellerId: widget.listing.sellerId,
            buyerId: order.buyerId,
            orderId: order.id,
            rating: _draftRating,
            comment: _commentController.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not submit review: $e')));
      }
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  Future<void> _toggleWatch() async {
    final next = !_watching;
    setState(() {
      _watching = next;
      _watcherCount += next ? 1 : -1;
    });
    try {
      await context.read<AppState>().setWatching(widget.listing.id, watching: next);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _watching = !next;
        _watcherCount += next ? -1 : 1;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not update — try again.')));
    }
  }

  Future<void> _buyNow() async {
    setState(() => _buying = true);
    final payments = context.read<PaymentsService>();
    try {
      await payments.buyListing(listingId: widget.listing.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paid! The seller has been notified.')),
        );
      }
    } on StripeException catch (e) {
      final code = e.error.code;
      if (code != FailureCode.Canceled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.error.localizedMessage ?? 'Payment failed.')),
        );
      }
    } on PayoutsNotReadyException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
      }
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final uid = context.watch<AppState>().uid;
    final isMine = listing.sellerId == uid;
    final isSold = listing.status == ListingStatus.sold;

    return Scaffold(
      appBar: AppBar(title: Text(listing.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ListingPhoto(photoUrl: listing.photoUrl, height: 320),
                Positioned(
                  top: 12,
                  right: 12,
                  child: isSold
                      ? const _SoldBadge()
                      : CountdownBadge(remaining: listing.remaining(DateTime.now())),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '£${listing.priceInPounds.toStringAsFixed(0)}',
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
                Text('${listing.sellerName} · ${listing.sellerCity}',
                    style: const TextStyle(color: S8llColors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            SellerRatingBadge(rating: _sellerRating),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 18, color: S8llColors.grey),
                const SizedBox(width: 6),
                Text(listing.delivery.label, style: const TextStyle(color: S8llColors.grey)),
              ],
            ),
            if (_watcherCount > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 18, color: S8llColors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _watcherCount == 1 ? '1 person watching' : '$_watcherCount people watching',
                    style: const TextStyle(color: S8llColors.grey),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (isSold) ...[
              const Text('This item has sold.', style: TextStyle(color: S8llColors.grey)),
              if (_myOrder != null) ...[
                const SizedBox(height: 16),
                if (_existingReview != null)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: S8llColors.lime, size: 18),
                      const SizedBox(width: 6),
                      Text('You rated this seller ${_existingReview!.rating}/5'),
                    ],
                  )
                else ...[
                  Text('Rate this seller', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  StarRatingInput(
                    value: _draftRating,
                    onChanged: (v) => setState(() => _draftRating = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(hintText: 'Add a comment (optional)'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: (_draftRating == 0 || _submittingReview) ? null : _submitReview,
                    child: Text(_submittingReview ? 'Submitting…' : 'Submit review'),
                  ),
                ],
              ],
            ] else if (isMine) ...[
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().bumpListing(listing.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bumped back to the top of the feed')),
                  );
                },
                child: const Text('Bump listing'),
              ),
              if (listing.delivery != DeliveryMethod.meetup) ...[
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PayoutsSetupScreen(paymentsService: context.read<PaymentsService>()),
                    ),
                  ),
                  child: const Text('Set up payouts'),
                ),
              ],
            ] else ...[
              if (listing.canBuyInApp)
                ElevatedButton(
                  onPressed: _buying ? null : _buyNow,
                  child: Text(_buying ? 'Processing…' : 'Buy now'),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _toggleWatch,
                icon: Icon(_watching ? Icons.visibility : Icons.visibility_outlined),
                label: Text(_watching ? 'Watching' : 'Watch'),
                style: _watching
                    ? OutlinedButton.styleFrom(
                        foregroundColor: S8llColors.lime,
                        side: const BorderSide(color: S8llColors.lime),
                      )
                    : null,
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(listingId: listing.id, buyerId: uid),
                  ),
                ),
                child: const Text('Message seller'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoldBadge extends StatelessWidget {
  const _SoldBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'SOLD',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
