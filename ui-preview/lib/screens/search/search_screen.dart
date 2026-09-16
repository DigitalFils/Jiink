import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/sample_data.dart';
import '../../models/models.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedCategories = [];
  double _minPrice = 0;
  double _maxPrice = 500;
  String _sortBy = 'Recommended';
  bool _verifiedOnly = false;
  bool _freeShipping = false;
  bool _newOnly = false;
  String _selectedCondition = 'All';
  String _selectedLocation = 'Anywhere';

  final List<String> _categories = [
    'Sneakers', 'Clothing', 'Electronics', 'Accessories',
    'Bags', 'Home & Garden', 'Collectibles', 'Beauty',
  ];

  final List<String> _sortOptions = [
    'Recommended', 'Price: Low to High', 'Price: High to Low',
    'Newest First', 'Most Popular', 'Ending Soon',
  ];

  final List<String> _conditions = ['All', 'New', 'Like New', 'Excellent', 'Good', 'Fair'];
  final List<String> _locations = ['Anywhere', 'Near Me', 'Manchester', 'London', 'Nationwide'];

  final List<String> _recentSearches = ['Nike sneakers', 'Vintage camera', 'North face', 'Leather bag'];
  final List<String> _trendingSearches = ['Jordan 1 Olive', 'Yeezy Boost', 'Carhartt Jacket', 'Polaroid Camera', 'AirPods Pro'];

  List<Product> get _filteredProducts {
    var results = SampleData.products.where((p) {
      if (_searchQuery.isNotEmpty &&
          !p.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !p.category.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedCategories.isNotEmpty && !_selectedCategories.contains(p.category)) {
        return false;
      }
      if (p.price < _minPrice || p.price > _maxPrice) return false;
      if (_verifiedOnly && !p.isVerified) return false;
      return true;
    }).toList();

    switch (_sortBy) {
      case 'Price: Low to High':
        results.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        results.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_searchQuery.isEmpty) _buildEmptySearch() else _buildSearchResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search products, brands, sellers...',
                  hintStyle: TextStyle(color: AppTheme.textMuted),
                  prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.accent),
            onPressed: () => _showFilterSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryChips(),
            const SizedBox(height: 24),
            _buildRecentSearches(),
            const SizedBox(height: 24),
            _buildTrendingSearches(),
            const SizedBox(height: 24),
            _buildAIRecommendation(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse Categories',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                    _searchController.text = category;
                    _searchQuery = category;
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Searches',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSearches.map((search) => ListTile(
          leading: const Icon(Icons.history, color: AppTheme.textMuted, size: 20),
          title: Text(
            search,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          trailing: const Icon(Icons.north_west, color: AppTheme.accent, size: 18),
          onTap: () {
            _searchController.text = search;
            setState(() => _searchQuery = search);
          },
          contentPadding: EdgeInsets.zero,
          minLeadingWidth: 24,
        )),
      ],
    );
  }

  Widget _buildTrendingSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_fire_department, color: AppTheme.liveRed, size: 20),
            SizedBox(width: 6),
            Text(
              'Trending Now',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._trendingSearches.asMap().entries.map((entry) {
          final index = entry.key;
          final search = entry.value;
          return ListTile(
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: index < 3 ? AppTheme.accent.withOpacity(0.2) : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: index < 3 ? AppTheme.accent : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            title: Text(
              search,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            ),
            trailing: index < 3 ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.liveRed.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'HOT',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.liveRed,
                ),
              ),
            ) : null,
            onTap: () {
              _searchController.text = search;
              setState(() => _searchQuery = search);
            },
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 36,
          );
        }),
      ],
    );
  }

  Widget _buildAIRecommendation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Shopping Assistant',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Describe what you want and let AI find perfect matches',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: AppTheme.accent, size: 18),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _filteredProducts;
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${results.length} results',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSortSheet(),
                  icon: const Icon(Icons.swap_vert, size: 18),
                  label: Text(_sortBy),
                ),
              ],
            ),
          ),
          if (_selectedCategories.isNotEmpty || _verifiedOnly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._selectedCategories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InputChip(
                        label: Text(cat),
                        onDeleted: () => setState(() => _selectedCategories.remove(cat)),
                      ),
                    )),
                    if (_verifiedOnly)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InputChip(
                          label: const Text('Verified'),
                          avatar: const Icon(Icons.verified, size: 16, color: AppTheme.accent),
                          onDeleted: () => setState(() => _verifiedOnly = false),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, color: AppTheme.textMuted, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No results found',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or search terms',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final product = results[index];
                      return _buildResultCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppTheme.surface);
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.timeLeft,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.background,
                    ),
                  ),
                ),
              ),
              if (product.isVerified)
                const Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(Icons.verified, color: AppTheme.accent, size: 18),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '£${product.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accent,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filters',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _selectedCategories.clear();
                                _minPrice = 0;
                                _maxPrice = 500;
                                _verifiedOnly = false;
                                _freeShipping = false;
                                _newOnly = false;
                              });
                            },
                            child: const Text('Reset All'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const Text(
                            'Price Range',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '£${_minPrice.toStringAsFixed(0)}',
                                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '£${_maxPrice.toStringAsFixed(0)}',
                                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          RangeSlider(
                            values: RangeValues(_minPrice, _maxPrice),
                            min: 0,
                            max: 1000,
                            divisions: 20,
                            activeColor: AppTheme.accent,
                            inactiveColor: AppTheme.surfaceLight,
                            onChanged: (values) {
                              setSheetState(() {
                                _minPrice = values.start;
                                _maxPrice = values.end;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Categories',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((category) {
                              final isSelected = _selectedCategories.contains(category);
                              return FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setSheetState(() {
                                    if (selected) {
                                      _selectedCategories.add(category);
                                    } else {
                                      _selectedCategories.remove(category);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          _buildFilterSwitch(
                            'Verified Sellers Only',
                            'Only show items from verified sellers',
                            _verifiedOnly,
                            (value) => setSheetState(() => _verifiedOnly = value),
                          ),
                          _buildFilterSwitch(
                            'Free Shipping',
                            'Items with free delivery',
                            _freeShipping,
                            (value) => setSheetState(() => _freeShipping = value),
                          ),
                          _buildFilterSwitch(
                            'New Items Only',
                            'Brand new condition',
                            _newOnly,
                            (value) => setSheetState(() => _newOnly = value),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Condition',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _conditions.map((condition) {
                              return ChoiceChip(
                                label: Text(condition),
                                selected: _selectedCondition == condition,
                                onSelected: (selected) {
                                  setSheetState(() => _selectedCondition = condition);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: _locations.map((location) {
                              return ChoiceChip(
                                label: Text(location),
                                selected: _selectedLocation == location,
                                onSelected: (selected) {
                                  setSheetState(() => _selectedLocation = location);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {});
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
            activeTrackColor: AppTheme.accent.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              ..._sortOptions.map((option) => ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: _sortBy == option ? FontWeight.w700 : FontWeight.w500,
                    color: _sortBy == option ? AppTheme.accent : AppTheme.textPrimary,
                  ),
                ),
                trailing: _sortBy == option
                    ? const Icon(Icons.check, color: AppTheme.accent)
                    : null,
                onTap: () {
                  setState(() => _sortBy = option);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
