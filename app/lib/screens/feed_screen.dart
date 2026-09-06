import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/listing_filter.dart';
import '../services/saved_searches_repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/drop_card.dart';
import '../widgets/logo.dart';
import 'listing_detail_screen.dart';

const _maxPriceOptions = <int?>[null, 2500, 5000, 10000, 25000];

/// Home: everything that's live right now, soonest to end first.
///
/// Ordering is the whole argument for this screen. A drop feed sorted
/// newest-first buries the thing with twenty minutes left under the thing
/// posted five minutes ago with eight hours to run. Sorted by what's about
/// to go, the top of the feed is always the part you'd regret missing.
///
/// Always dark regardless of the app's light/dark setting — the feed reads
/// as itself against black in a way it doesn't against an off-white page.
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

  /// One clock for the whole grid. Every countdown pill reads from this, so
  /// the feed ticks in step off a single timer rather than each card
  /// running its own.
  late DateTime _now;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now()),
    );
    final uid = context.read<AppState>().uid;
    _savedSearchesSub =
        context.read<SavedSearchesRepository>().savedSearchesFor(uid).listen((searches) {
      if (mounted) setState(() => _savedSearches = searches);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(S8llRadius.lg)),
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
                  const Text(
                    'Search & filter',
                    style: TextStyle(
                      color: S8llColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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

    // Expiry first, then blocking, then the user's own search/category/
    // price choices — so the "N live now" count means what it says rather
    // than counting every listing ever posted.
    final onFeed = stillLive(appState.listings, now: _now)
        .where((l) => !blocked.contains(l.sellerId))
        .toList()
      ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));

    // Sold items stay on the feed — a card marked SOLD is proof the place
    // works — but they are not what "N live now" is counting. Nothing about
    // them is live any more.
    final liveCount = onFeed.where((l) => l.status != ListingStatus.sold).length;

    final listings = filterListings(
      onFeed,
      query: _searchController.text,
      category: _category,
      maxPriceCents: _maxPriceCents,
    );

    return Scaffold(
      backgroundColor: S8llColors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(
              liveCount: liveCount,
              filtersActive: _hasActiveFilters,
              onSearch: () => _openFilters(uid),
            ),
            _CategoryStrip(
              selected: _category,
              onSelect: (category) => setState(() => _category = category),
            ),
            Expanded(
              child: listings.isEmpty
                  ? _EmptyFeed(hasFilters: _hasActiveFilters)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        S8llSpacing.lg,
                        S8llSpacing.sm,
                        S8llSpacing.lg,
                        // The nav bar floats over the page, so the last row
                        // needs to clear it — without this the bottom card
                        // sits permanently underneath the lime button.
                        S8llBottomNavBar.clearance,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: S8llSpacing.md,
                        crossAxisSpacing: S8llSpacing.md,
                        // Sized for what the card actually holds: 14px of
                        // padding top and bottom, a title that may run to
                        // two lines, the 32px price and the meta row —
                        // about 133px — on top of a photo that wants to be
                        // roughly square at this column width. Too tight
                        // and the photo has to give up more than it has,
                        // which is what used to clip the price in half.
                        childAspectRatio: 0.58,
                      ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return DropCard(
                          listing: listing,
                          now: _now,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(listing: listing),
                            ),
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

/// Wordmark, the live count, and the way into search. The count is the
/// real number of listings still inside their window — it moves on its own
/// as drops end, which is the point of putting it up here.
class _Header extends StatelessWidget {
  const _Header({
    required this.liveCount,
    required this.filtersActive,
    required this.onSearch,
  });

  final int liveCount;
  final bool filtersActive;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      // Everything here is Flexible + scaleDown. At the default text size
      // the wordmark and the pill both sit at their natural width, but a
      // phone set to a large accessibility font size (or a five-figure live
      // count) used to push the search button clean off the right edge.
      // Now the type gives way instead.
      child: Row(
        children: [
          const Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: S8llLogo(size: 52),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: S8llColors.charcoal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        children: [
                          const Icon(Icons.circle, color: S8llColors.live, size: 8),
                          const SizedBox(width: 6),
                          Text(
                            '$liveCount live now',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: S8llColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onSearch,
                  tooltip: 'Search and filter',
                  icon: Icon(
                    filtersActive ? Icons.filter_alt : Icons.search,
                    color: filtersActive ? S8llColors.lime : S8llColors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Categories on the feed itself rather than only inside the filter sheet —
/// it's the one filter people reach for constantly, and burying it behind
/// an icon made the feed look like an undifferentiated wall.
class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.selected, required this.onSelect});

  final ListingCategory? selected;
  final ValueChanged<ListingCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: S8llSpacing.lg),
        children: [
          _CategoryChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final category in ListingCategory.values)
            _CategoryChip(
              label: category.label,
              selected: selected == category,
              onTap: () => onSelect(selected == category ? null : category),
            ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: S8llSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? S8llColors.lime : S8llColors.charcoal,
            borderRadius: BorderRadius.circular(S8llRadius.pill),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? S8llColors.black : S8llColors.grey,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
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
            Icon(
              hasFilters ? Icons.search_off_rounded : Icons.local_fire_department_outlined,
              size: 48,
              color: S8llColors.greyLow,
            ),
            const SizedBox(height: S8llSpacing.md),
            Text(
              hasFilters ? 'Nothing matches right now' : 'Nothing dropping yet',
              style: const TextStyle(
                color: S8llColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: S8llSpacing.sm),
            Text(
              hasFilters
                  ? 'Try clearing a filter or searching something else.'
                  : 'Tap the lime button to be the first to list.',
              style: const TextStyle(color: S8llColors.grey, fontSize: 13),
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
