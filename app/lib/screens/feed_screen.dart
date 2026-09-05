import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/listing_filter.dart';
import '../services/saved_searches_repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'listing_detail_screen.dart';

const _maxPriceOptions = <int?>[null, 2500, 5000, 10000, 25000];

/// The main feed — a scrollable 2-column grid so multiple live listings are
/// visible at once, rather than one full-screen card at a time. Always
/// renders dark regardless of the app's light/dark setting: a drop feed
/// reads as itself against black the way it doesn't against an off-white
/// page.
///
/// Search/category/price filtering and saved searches are all real and
/// unchanged from before — behind the search icon in the header instead of
/// sitting permanently on screen.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchController = TextEditingController();
  ListingCategory? _category;
  int? _maxPriceCents;

  List<SavedSearch> _savedSearches = [];
  StreamSubscription<List<SavedSearch>>? _savedSearchesSub;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AppState>().uid;
    _savedSearchesSub =
        context.read<SavedSearchesRepository>().savedSearchesFor(uid).listen((searches) {
      if (mounted) setState(() => _savedSearches = searches);
    });
  }

  @override
  void dispose() {
    _savedSearchesSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _searchController.text.trim().isNotEmpty || _category != null || _maxPriceCents != null;

  void _applySearch(SavedSearch search) {
    setState(() {
      _searchController.text = search.query;
      _category = search.category;
      _maxPriceCents = search.maxPriceCents;
    });
  }

  Future<void> _saveSearch(String buyerId) async {
    try {
      await context.read<SavedSearchesRepository>().save(
            buyerId: buyerId,
            query: _searchController.text.trim(),
            category: _category,
            maxPriceCents: _maxPriceCents,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Search saved — we\'ll flag new matches.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save search: $e')));
      }
    }
  }

  Future<void> _openFilters(String uid) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: S8llColors.charcoal,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(S8llRadius.md)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void update(VoidCallback fn) {
              setState(fn);
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: S8llSpacing.lg,
                right: S8llSpacing.lg,
                top: S8llSpacing.lg,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + S8llSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search & filter', style: Theme.of(sheetContext).textTheme.titleLarge),
                  const SizedBox(height: S8llSpacing.lg),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => update(() {}),
                    style: const TextStyle(color: S8llColors.white),
                    decoration: const InputDecoration(
                      hintText: 'Search listings',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: S8llSpacing.md),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _category == null,
                          onTap: () => update(() => _category = null),
                        ),
                        for (final category in ListingCategory.values)
                          Padding(
                            padding: const EdgeInsets.only(left: S8llSpacing.xs),
                            child: _FilterChip(
                              label: category.label,
                              selected: _category == category,
                              onTap: () => update(() => _category = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: S8llSpacing.sm),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final option in _maxPriceOptions)
                          Padding(
                            padding: const EdgeInsets.only(right: S8llSpacing.xs),
                            child: _FilterChip(
                              label: option == null ? 'Any price' : 'Under £${option ~/ 100}',
                              selected: _maxPriceCents == option,
                              onTap: () => update(() => _maxPriceCents = option),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_hasActiveFilters) ...[
                    const SizedBox(height: S8llSpacing.md),
                    TextButton.icon(
                      onPressed: () => _saveSearch(uid),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Save this search'),
                    ),
                  ],
                  if (_savedSearches.isNotEmpty) ...[
                    const SizedBox(height: S8llSpacing.sm),
                    const Text('Saved searches', style: TextStyle(color: S8llColors.grey, fontSize: 12)),
                    const SizedBox(height: S8llSpacing.xs),
                    Wrap(
                      spacing: S8llSpacing.xs,
                      runSpacing: S8llSpacing.xs,
                      children: [
                        for (final search in _savedSearches)
                          InputChip(
                            label: Text(search.query.isEmpty ? 'Saved search' : search.query),
                            onPressed: () {
                              _applySearch(search);
                              setSheetState(() {});
                            },
                            onDeleted: () =>
                                context.read<SavedSearchesRepository>().delete(search.id),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final uid = appState.uid;
    final blocked = appState.profile?.blockedUserIds ?? const [];
    final visible = appState.listings.where((l) => !blocked.contains(l.sellerId)).toList();
    final listings = filterListings(
      visible,
      query: _searchController.text,
      category: _category,
      maxPriceCents: _maxPriceCents,
    );

    return Scaffold(
      backgroundColor: S8llColors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: S8llSpacing.lg, vertical: S8llSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'S8LL',
                    style: TextStyle(
                      color: S8llColors.lime,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: S8llColors.charcoal,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${visible.length} live now',
                          style: const TextStyle(
                            color: S8llColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: S8llSpacing.sm),
                      GestureDetector(
                        onTap: () => _openFilters(uid),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _hasActiveFilters ? S8llColors.lime : S8llColors.charcoal,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search,
                            size: 18,
                            color: _hasActiveFilters ? S8llColors.black : S8llColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: listings.isEmpty
                  ? _EmptyFeed(hasFilters: _hasActiveFilters)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        S8llSpacing.lg,
                        S8llSpacing.xs,
                        S8llSpacing.lg,
                        S8llSpacing.lg,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: S8llSpacing.md,
                        crossAxisSpacing: S8llSpacing.md,
                        childAspectRatio: 0.66,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return _GridCard(
                          listing: listing,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ListingDetailScreen(listing: listing)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One card in the feed grid: bounded photo up top with a small
/// countdown/sold badge overlaid, real price/title/seller info below on a
/// charcoal chip background so cards read distinctly against the black page.
class _GridCard extends StatelessWidget {
  const _GridCard({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: S8llColors.charcoal,
          borderRadius: BorderRadius.circular(S8llRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _FullBleedPhoto(url: listing.photoUrl),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: listing.status == ListingStatus.sold
                        ? const _SoldBadge(compact: true)
                        : _PulsingCountdown(listing: listing, compact: true),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(S8llSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '£${listing.priceInPounds.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: S8llColors.lime,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.watcherCount > 0
                        ? '${listing.sellerName} · ${listing.watcherCount} watching'
                        : listing.sellerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullBleedPhoto extends StatelessWidget {
  const _FullBleedPhoto({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const ColoredBox(
        color: S8llColors.charcoal,
        child: Center(
          child: Icon(Icons.shopping_bag_outlined, size: 64, color: S8llColors.greyLow),
        ),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: S8llColors.charcoal,
          child: Center(child: CircularProgressIndicator(color: S8llColors.lime)),
        );
      },
      errorBuilder: (context, error, stack) => const ColoredBox(
        color: S8llColors.charcoal,
        child: Center(
          child: Icon(Icons.broken_image_outlined, size: 64, color: S8llColors.greyLow),
        ),
      ),
    );
  }
}

/// A pulsing pill showing the listing's real time-remaining ("2h left",
/// "45m left" — turning red under 30 minutes), same text as [CountdownBadge]
/// elsewhere in the app. The pulse is decoration; the number is real —
/// there's no per-second countdown to show, so this never claims one.
class _PulsingCountdown extends StatefulWidget {
  const _PulsingCountdown({required this.listing, this.compact = false});

  final Listing listing;
  final bool compact;

  @override
  State<_PulsingCountdown> createState() => _PulsingCountdownState();
}

class _PulsingCountdownState extends State<_PulsingCountdown> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.listing.remaining(DateTime.now());
    final expiring = remaining.inMinutes <= 30 && remaining > Duration.zero;
    final label = remaining == Duration.zero
        ? 'Expired'
        : remaining.inHours >= 1
            ? '${remaining.inHours}h left'
            : '${remaining.inMinutes}m left';
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 14,
          vertical: widget.compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          color: expiring ? Colors.redAccent : S8llColors.lime,
          borderRadius: BorderRadius.circular(999),
          boxShadow: widget.compact
              ? null
              : [
                  BoxShadow(
                    color: (expiring ? Colors.redAccent : S8llColors.lime).withValues(alpha: 0.5),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: expiring ? Colors.white : S8llColors.black,
            fontWeight: FontWeight.w800,
            fontSize: widget.compact ? 11 : 15,
          ),
        ),
      ),
    );
  }
}

class _SoldBadge extends StatelessWidget {
  const _SoldBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: compact ? 4 : 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
      child: Text(
        'SOLD',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
          fontSize: compact ? 11 : 15,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: S8llSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasFilters ? 'Nothing matches right now' : 'Nothing dropping yet',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try clearing a filter or searching something else.'
                  : 'Tap the camera below to be the first to list.',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: S8llSpacing.xs),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: S8llColors.charcoalHigh,
        labelStyle: const TextStyle(color: S8llColors.white),
        selectedColor: S8llColors.limeSoft,
        checkmarkColor: S8llColors.lime,
      ),
    );
  }
}
