import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo.dart';
import '../../widgets/product_card.dart';
import '../../data/sample_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const S8LLLogo(size: 52),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.circle, color: AppTheme.liveRed, size: 8),
                              SizedBox(width: 6),
                              Text(
                                '4 live now',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.search, color: AppTheme.textSecondary, size: 28),
                          onPressed: () => Navigator.pushNamed(context, '/search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: AppTheme.textMuted, size: 22),
                        SizedBox(width: 12),
                        Text(
                          'Search products, brands, sellers...',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Quick Features
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildQuickFeatures(context),
              ),
            ),
            // Flash Sale Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildFlashSaleBanner(context),
              ),
            ),
            // Live Stream Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildLiveStreamBanner(context),
              ),
            ),
            // Group Buy Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildGroupBuyBanner(context),
              ),
            ),
            // Section Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Near You',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'See all',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Product Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = SampleData.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.pushNamed(context, '/product', arguments: product);
                      },
                    );
                  },
                  childCount: SampleData.products.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFeatures(BuildContext context) {
    final features = [
      QuickFeature(icon: Icons.map, label: 'Map View', color: AppTheme.info, route: '/map'),
      QuickFeature(icon: Icons.live_tv, label: 'Live', color: AppTheme.liveRed, route: '/live'),
      QuickFeature(icon: Icons.view_in_ar, label: 'AR Try-On', color: AppTheme.gold, route: '/ar'),
      QuickFeature(icon: Icons.groups, label: 'Group Buy', color: AppTheme.success, route: '/groupbuy'),
      QuickFeature(icon: Icons.verified_user, label: 'Dewu Auth', color: AppTheme.accent, route: '/auth'),
      QuickFeature(icon: Icons.auto_awesome, label: 'AI Helper', color: AppTheme.warning, route: '/ai'),
      QuickFeature(icon: Icons.account_balance_wallet, label: 'Wallet', color: AppTheme.accentDark, route: '/wallet'),
      QuickFeature(icon: Icons.favorite, label: 'Wishlist', color: AppTheme.liveRed, route: '/wishlist'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
        children: features.map((feature) {
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, feature.route),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: feature.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(feature.icon, color: feature.color, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  feature.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFlashSaleBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/flashsale'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFFF6B35), Color(0xFFFF3B30)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '限时秒杀',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Up to 70% OFF • Ends soon',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Shop Now',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                children: [
                  Text(
                    '02:14:32',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '时 分 秒',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStreamBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/live'),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withOpacity(0.85),
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.liveRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'LIVE NOW',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.liveRed,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sneaker Drop Live',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_red_eye, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '2.8k watching • Exclusive deals',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupBuyBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/groupbuy'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.groups, color: AppTheme.success, size: 30),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '拼单省钱 Group Buy',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Team up for unbeatable prices. Save up to 70%!',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person, color: AppTheme.accent, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '12,847 active groups',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class QuickFeature {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  QuickFeature({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}
