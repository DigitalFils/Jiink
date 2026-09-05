import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../services/offers_repository.dart';
import '../services/payments_service.dart';
import '../services/reviews_repository.dart';
import '../services/trust_safety_repository.dart';
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
  StreamSubscription<PurchaseOrder?>? _myOrderSub;
  PurchaseOrder? _saleOrder;
  StreamSubscription<PurchaseOrder?>? _saleOrderSub;
  Review? _existingReview;
  StreamSubscription<Review?>? _reviewSub;
  int _draftRating = 0;
  bool _submittingReview = false;
  bool _savingTracking = false;
  final _commentController = TextEditingController();
  final _trackingController = TextEditingController();
  final _carrierController = TextEditingController();

  Offer? _myOffer;
  StreamSubscription<Offer?>? _myOfferSub;
  List<Offer> _pendingOffers = [];
  StreamSubscription<List<Offer>>? _pendingOffersSub;

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
      _myOrderSub = reviews
          .orderForPurchaseStream(buyerId: uid, listingId: widget.listing.id)
          .listen((order) {
        if (!mounted || order == null) return;
        setState(() => _myOrder = order);
        _reviewSub ??= reviews.reviewForListing(widget.listing.id).listen((review) {
          if (mounted) setState(() => _existingReview = review);
        });
      });
    } else if (isSold && isMine) {
      _saleOrderSub = reviews
          .orderForSaleStream(sellerId: uid, listingId: widget.listing.id)
          .listen((order) {
        if (mounted) setState(() => _saleOrder = order);
      });
    }

    final offers = context.read<OffersRepository>();
    if (isMine) {
      _pendingOffersSub = offers.pendingOffersForListing(widget.listing.id, uid).listen((pending) {
        if (mounted) setState(() => _pendingOffers = pending);
      });
    } else if (!isSold) {
      _myOfferSub = offers.offerFor(listingId: widget.listing.id, buyerId: uid).listen((offer) {
        if (mounted) setState(() => _myOffer = offer);
      });
    }
  }

  @override
  void dispose() {
    _reviewSub?.cancel();
    _myOrderSub?.cancel();
    _saleOrderSub?.cancel();
    _myOfferSub?.cancel();
    _pendingOffersSub?.cancel();
    _commentController.dispose();
    _trackingController.dispose();
    _carrierController.dispose();
    super.dispose();
  }

  /// Whole-pound quick-offer suggestions (90%/80%/70% of the asking price),
  /// deduplicated and kept strictly below the asking price so every chip is
  /// a valid offer on its own.
  List<int> _quickOfferPounds() {
    final priceInPounds = widget.listing.priceInPounds;
    final pounds = <int>{
      for (final ratio in [0.9, 0.8, 0.7]) (priceInPounds * ratio).round(),
    }.where((p) => p > 0 && p < priceInPounds).toList()
      ..sort((a, b) => b.compareTo(a));
    return pounds;
  }

  Future<void> _showMakeOfferDialog() async {
    final controller = TextEditingController();
    final quickOfferPounds = _quickOfferPounds();
    final offerPounds = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make an offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quickOfferPounds.isNotEmpty) ...[
              Text('Quick offer', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: S8llSpacing.xs),
              Wrap(
                spacing: S8llSpacing.sm,
                children: [
                  for (final pounds in quickOfferPounds)
                    ActionChip(
                      label: Text('£$pounds'),
                      onPressed: () => controller.text = '$pounds',
                    ),
                ],
              ),
              const SizedBox(height: S8llSpacing.md),
            ],
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '£',
                hintText: 'Less than £${widget.listing.priceInPounds.toStringAsFixed(0)}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(double.tryParse(controller.text)),
            child: const Text('Send offer'),
          ),
        ],
      ),
    );
    if (!mounted || offerPounds == null || offerPounds <= 0) return;

    final offerCents = (offerPounds * 100).round();
    if (offerCents >= widget.listing.priceCents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your offer must be less than the asking price.')),
      );
      return;
    }

    try {
      await context.read<OffersRepository>().makeOffer(
            listingId: widget.listing.id,
            sellerId: widget.listing.sellerId,
            buyerId: context.read<AppState>().uid,
            offerCents: offerCents,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not send offer: $e')));
      }
    }
  }

  Future<void> _respondToOffer(Offer offer, {required bool accept}) async {
    try {
      await context.read<OffersRepository>().respondToOffer(
            listingId: offer.listingId,
            buyerId: offer.buyerId,
            accept: accept,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not respond to offer: $e')));
      }
    }
  }

  Future<void> _saveTracking() async {
    final order = _saleOrder;
    final trackingNumber = _trackingController.text.trim();
    if (order == null || trackingNumber.isEmpty) return;
    setState(() => _savingTracking = true);
    try {
      final carrier = _carrierController.text.trim();
      await context.read<ReviewsRepository>().setTracking(
            orderId: order.id,
            trackingNumber: trackingNumber,
            carrier: carrier.isEmpty ? null : carrier,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save tracking: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingTracking = false);
    }
  }

  Future<void> _showReportDialog() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report this listing'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "What's wrong with it?"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
    if (!mounted || reason == null || reason.isEmpty) return;

    try {
      await context.read<TrustSafetyRepository>().report(
            reporterId: context.read<AppState>().uid,
            targetType: ReportTargetType.listing,
            targetId: widget.listing.id,
            reason: reason,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Report submitted — thank you.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not submit report: $e')));
      }
    }
  }

  Future<void> _toggleBlockSeller() async {
    final appState = context.read<AppState>();
    final alreadyBlocked = appState.profile?.hasBlocked(widget.listing.sellerId) ?? false;
    try {
      await appState.setBlocked(widget.listing.sellerId, blocked: !alreadyBlocked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              alreadyBlocked
                  ? 'Unblocked ${widget.listing.sellerName}.'
                  : "Blocked ${widget.listing.sellerName} — their listings won't show in your feed.",
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    }
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

  // No s8ll.com yet (SETUP.md flags this same gap for the Stripe return
  // URLs) — sharing the listing's real details is still useful on its
  // own, so this doesn't invent a link to a domain that isn't live.
  void _share() {
    final listing = widget.listing;
    final remaining = listing.remaining(DateTime.now());
    final timeLeft = remaining == Duration.zero
        ? 'Sold or expired'
        : remaining.inHours >= 1
            ? '${remaining.inHours}h left'
            : '${remaining.inMinutes}m left';
    SharePlus.instance.share(
      ShareParams(
        text: '${listing.title} — £${listing.priceInPounds.toStringAsFixed(0)} '
            '(${listing.sellerCity}, $timeLeft)\nOn S8LL — sells today or it\'s gone.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final appState = context.watch<AppState>();
    final uid = appState.uid;
    final isMine = listing.sellerId == uid;
    final isSold = listing.status == ListingStatus.sold;
    final hasBlockedSeller = appState.profile?.hasBlocked(listing.sellerId) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(listing.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: _share,
          ),
          if (!isMine)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') _showReportDialog();
                if (value == 'block') _toggleBlockSeller();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'report', child: Text('Report listing')),
                PopupMenuItem(
                  value: 'block',
                  child: Text(hasBlockedSeller ? 'Unblock seller' : 'Block seller'),
                ),
              ],
            ),
        ],
      ),
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
                Icon(Icons.person_outline, size: 18, color: context.s8ll.textSecondary),
                const SizedBox(width: 6),
                Text('${listing.sellerName} · ${listing.sellerCity}',
                    style: TextStyle(color: context.s8ll.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            SellerRatingBadge(rating: _sellerRating),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined, size: 18, color: context.s8ll.textSecondary),
                const SizedBox(width: 6),
                Text(listing.delivery.label, style: TextStyle(color: context.s8ll.textSecondary)),
              ],
            ),
            if (_watcherCount > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 18, color: context.s8ll.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _watcherCount == 1 ? '1 person watching' : '$_watcherCount people watching',
                    style: TextStyle(color: context.s8ll.textSecondary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (isSold) ...[
              Text('This item has sold.', style: TextStyle(color: context.s8ll.textSecondary)),
              if (isMine && _saleOrder != null) ...[
                const SizedBox(height: 16),
                Text('Shipment tracking', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (_saleOrder!.hasTracking)
                  Row(
                    children: [
                      const Icon(Icons.local_shipping, color: S8llColors.lime, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _saleOrder!.carrier == null
                              ? _saleOrder!.trackingNumber!
                              : '${_saleOrder!.trackingNumber} · ${_saleOrder!.carrier}',
                        ),
                      ),
                    ],
                  )
                else ...[
                  TextField(
                    controller: _trackingController,
                    decoration: const InputDecoration(hintText: 'Tracking number'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _carrierController,
                    decoration: const InputDecoration(hintText: 'Carrier (optional)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _savingTracking ? null : _saveTracking,
                    child: Text(_savingTracking ? 'Saving…' : 'Save tracking number'),
                  ),
                ],
              ],
              if (!isMine && _myOrder != null) ...[
                const SizedBox(height: 16),
                if (_myOrder!.hasTracking)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping, color: S8llColors.lime, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _myOrder!.carrier == null
                                ? 'Tracking: ${_myOrder!.trackingNumber}'
                                : 'Tracking: ${_myOrder!.trackingNumber} · ${_myOrder!.carrier}',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      "The seller hasn't added tracking yet.",
                      style: TextStyle(color: context.s8ll.textSecondary),
                    ),
                  ),
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
              if (_pendingOffers.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Offers', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final offer in _pendingOffers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '£${offer.offerInPounds.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _respondToOffer(offer, accept: false),
                          child: const Text('Decline'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _respondToOffer(offer, accept: true),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ),
              ],
            ] else ...[
              if (listing.canBuyInApp)
                ElevatedButton(
                  onPressed: _buying ? null : _buyNow,
                  child: Text(
                    _buying
                        ? 'Processing…'
                        : _myOffer?.status == OfferStatus.accepted
                            ? 'Buy now at £${_myOffer!.offerInPounds.toStringAsFixed(0)}'
                            : 'Buy now',
                  ),
                ),
              if (listing.canBuyInApp) ...[
                const SizedBox(height: 10),
                switch (_myOffer?.status) {
                  null => OutlinedButton(
                      onPressed: _showMakeOfferDialog,
                      child: const Text('Make an offer'),
                    ),
                  OfferStatus.pending => Text(
                      'Your offer of £${_myOffer!.offerInPounds.toStringAsFixed(0)} is pending — waiting for the seller',
                      style: TextStyle(color: context.s8ll.textSecondary),
                    ),
                  OfferStatus.accepted => const Row(
                      children: [
                        Icon(Icons.check_circle, color: S8llColors.lime, size: 18),
                        SizedBox(width: 6),
                        Text('Offer accepted — buy now at the price above'),
                      ],
                    ),
                  OfferStatus.declined => Text(
                      'Your offer was declined',
                      style: TextStyle(color: context.s8ll.textSecondary),
                    ),
                },
              ],
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
