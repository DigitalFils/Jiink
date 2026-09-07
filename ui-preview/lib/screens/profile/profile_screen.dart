import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pushNamed(context, '/wishlist'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: AppTheme.textSecondary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildProfileHeader(context),
              const SizedBox(height: 24),
              _buildStats(),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildOrderTabs(),
              const SizedBox(height: 24),
              _buildSellerLevelCard(),
              const SizedBox(height: 24),
              const Text(
                'My Collection',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildCollectionGrid(),
              const SizedBox(height: 24),
              _buildMenuItems(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=68'),
              backgroundColor: AppTheme.surfaceLight,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified, color: AppTheme.accent, size: 22),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Алексей Волков',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.star, color: AppTheme.accent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '4.9 • Gold Seller',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                '@alexey_s8ll • Manchester',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Edit Profile', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/sell'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('+ Sell', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Assets',
            value: '£2,840',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            label: 'Followers',
            value: '4.2K',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.sell,
            label: 'Sales',
            value: '127',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ProfileAction(icon: Icons.account_balance_wallet, label: 'Wallet', color: AppTheme.accent, route: '/wallet'),
      ProfileAction(icon: Icons.favorite_border, label: 'Wishlist', color: AppTheme.liveRed, route: '/wishlist'),
      ProfileAction(icon: Icons.local_shipping, label: 'Orders', color: AppTheme.info, route: null),
      ProfileAction(icon: Icons.receipt_long, label: 'Selling', color: AppTheme.success, route: null),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () {
              if (action.route != null) {
                Navigator.pushNamed(context, action.route!);
              }
            },
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: action.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  action.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _OrderTab(
              label: '待付款',
              count: 2,
              isActive: true,
            ),
          ),
          Expanded(
            child: _OrderTab(
              label: '待发货',
              count: 1,
              isActive: false,
            ),
          ),
          Expanded(
            child: _OrderTab(
              label: '已完成',
              count: 0,
              isActive: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerLevelCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.gold.withOpacity(0.2),
            AppTheme.accent.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.workspace_premium, color: AppTheme.gold, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Gold Seller',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.gold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Level 4',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  child: LinearProgressIndicator(
                    value: 0.72,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(AppTheme.gold),
                    minHeight: 6,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '72% to Platinum • 28 more sales needed',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionGrid() {
    final items = [
      {'title': 'Sneakers', 'price': '£95', 'image': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=300'},
      {'title': 'Hoodie', 'price': '£112', 'image': 'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=300'},
      {'title': 'Leather Bag', 'price': '£58', 'image': 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=300'},
      {'title': 'Cap', 'price': '£120', 'image': 'https://images.unsplash.com/photo-1521369909029-2afed882baee?w=300'},
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Image.network(
                    item['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: AppTheme.surface);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['price']!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final items = [
      MenuItem(icon: Icons.auto_awesome, label: 'AI Shopping Assistant', subtitle: 'Get personalized recommendations', route: '/ai', color: AppTheme.accent),
      MenuItem(icon: Icons.verified_user, label: 'Authentication Center', subtitle: 'Verify your purchases', route: '/auth', color: AppTheme.success),
      MenuItem(icon: Icons.location_on, label: 'Address Book', subtitle: 'Manage delivery addresses', route: null, color: AppTheme.info),
      MenuItem(icon: Icons.notifications, label: 'Notifications', subtitle: 'Price alerts & updates', route: null, color: AppTheme.warning),
      MenuItem(icon: Icons.help_outline, label: 'Help & Support', subtitle: '24/7 customer service', route: null, color: AppTheme.textSecondary),
      MenuItem(icon: Icons.info_outline, label: 'About S8LL', subtitle: 'Version 2.0.0', route: null, color: AppTheme.textMuted),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == items.length - 1;
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            title: Text(
              item.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              item.subtitle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
            onTap: () {
              if (item.route != null) {
                Navigator.pushNamed(context, item.route!);
              }
            },
            shape: isLast
                ? null
                : Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderTab extends StatelessWidget {
  final String label;
  final int count;
  final bool isActive;

  const _OrderTab({
    required this.label,
    required this.count,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '$label $count',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isActive ? AppTheme.background : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class ProfileAction {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;

  ProfileAction({
    required this.icon,
    required this.label,
    required this.color,
    this.route,
  });
}

class MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final String? route;
  final Color color;

  MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.route,
    required this.color,
  });
}
