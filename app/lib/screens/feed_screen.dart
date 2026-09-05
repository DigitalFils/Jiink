import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/listing_filter.dart';
import '../services/saved_searches_repository.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/listing_card.dart';
import 'listing_detail_screen.dart';

const _maxPriceOptions = <int?>[null, 2500, 5000, 10000, 25000];

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
      appBar: AppBar(title: const Text('S8LL')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S8llSpacing.md, S8llSpacing.sm, S8llSpacing.md, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search listings',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: S8llSpacing.md, vertical: S8llSpacing.sm),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final category in ListingCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(left: S8llSpacing.xs),
                    child: _FilterChip(
                      label: category.label,
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: S8llSpacing.md),
              children: [
                for (final option in _maxPriceOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: S8llSpacing.xs),
                    child: _FilterChip(
                      label: option == null ? 'Any price' : 'Under £${option ~/ 100}',
                      selected: _maxPriceCents == option,
                      onTap: () => setState(() => _maxPriceCents = option),
                    ),
                  ),
              ],
            ),
          ),
          if (_savedSearches.isNotEmpty || _hasActiveFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(S8llSpacing.md, S8llSpacing.sm, S8llSpacing.md, 0),
              child: Row(
                children: [
                  if (_hasActiveFilters)
                    TextButton.icon(
                      onPressed: () => _saveSearch(uid),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Save this search'),
                    ),
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final search in _savedSearches)
                            Padding(
                              padding: const EdgeInsets.only(right: S8llSpacing.xs),
                              child: InputChip(
                                label: Text(search.query.isEmpty ? 'Saved search' : search.query),
                                onPressed: () => _applySearch(search),
                                onDeleted: () =>
                                    context.read<SavedSearchesRepository>().delete(search.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: listings.isEmpty
                ? const Center(child: Text('Nothing matches right now.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: S8llSpacing.sm),
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
          ),
        ],
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: S8llColors.limeSoft,
      checkmarkColor: S8llColors.lime,
    );
  }
}
