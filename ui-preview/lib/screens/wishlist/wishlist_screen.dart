import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/sample_data.dart';
import '../../models/models.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Product> _wishlistItems = [];
  final Map<String, Collection> _collections = {
    'Sneakers': Collection(
      name: 'Sneakers',
      icon: Icons.sports_soccer,
      items: [],
      color: AppTheme.accent,
    ),
    'Streetwear': Collection(
      name: 'Streetwear',
      icon: Icons.checkroom,
      items: [],
      color: AppTheme.info,
    ),
    'Electronics': Collection(
      name: 'Electronics',
      icon: Icons.devices,
      items: [],
      color: AppTheme.warning,
    ),
    'Gifts': Collection(
      name: 'Gifts',
      icon: Icons.card_giftcard,
      items: [],
      color: AppTheme.gold,
    ),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _wishlistItems = List.from(SampleData.products.take(5));
    _collections['Sneakers']!.items = [SampleData.products[0], SampleData.products[1]];
    _collections['Streetwear']!.items = [SampleData.products[3]];
    _collections['Electronics']!.items = [SampleData.products[2]];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _removeItem(String id) {
    setState(() {
      _wishlistItems.removeWhere((p) => p.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from wishlist'),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _setPriceAlert(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Price Alert',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get notified when ${product.title} drops below your target price',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: product.price.toStringAsFixed(0),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Target Price (£)',
                prefixText: '£ ',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Price alert set! You\'ll be notified.'),
                      backgroundColor: AppTheme.accent,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Create Alert'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsBar(),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Wishlist'),
                Tab(text: 'Collections'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWishlist(),
                  _buildCollections(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Saved Items',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search, color: AppTheme.textSecondary),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.sort, color: AppTheme.textSecondary),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('${_wishlistItems.length}', 'Items'),
            Container(width: 1, height: 36, color: AppTheme.border),
            _buildStatItem('£${_wishlistItems.fold(0.0, (sum, p) => sum + p.price).toStringAsFixed(0)}', 'Total Value'),
            Container(width: 1, height: 36, color: AppTheme.border),
            _buildStatItem('3', 'Price Alerts', color: AppTheme.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildWishlist() {
    if (_wishlistItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, color: AppTheme.textMuted, size: 64),
            SizedBox(height: 16),
            Text(
              'No items saved yet',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart icon on any product to save it',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _wishlistItems.length,
      itemBuilder: (context, index) {
        final product = _wishlistItems[index];
        final priceDrop = index % 3 == 0;
        return Dismissible(
          key: Key(product.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppTheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _removeItem(product.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'wishlist-${product.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: AppTheme.surfaceLight);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '£${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (priceDrop)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '↓ 15%',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.timeLeft,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_active_outlined, color: AppTheme.warning, size: 22),
                      onPressed: () => _setPriceAlert(product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite, color: AppTheme.liveRed, size: 22),
                      onPressed: () => _removeItem(product.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollections() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: () => _showCreateCollectionDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Create New Collection'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 20),
        ..._collections.values.map((collection) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: collection.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(collection.icon, color: collection.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collection.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${collection.items.length} items',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                    ],
                  ),
                ),
                if (collection.items.isNotEmpty)
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: collection.items.length,
                      itemBuilder: (context, index) {
                        final item = collection.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: AppTheme.surfaceLight);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showCreateCollectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('New Collection'),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Collection name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _collections[nameController.text] = Collection(
                      name: nameController.text,
                      icon: Icons.folder,
                      items: [],
                      color: AppTheme.accent,
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class Collection {
  final String name;
  final IconData icon;
  List<Product> items;
  final Color color;

  Collection({
    required this.name,
    required this.icon,
    required this.items,
    required this.color,
  });
}
