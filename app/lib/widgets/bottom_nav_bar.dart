import 'package:flutter/material.dart';

import '../theme.dart';

/// The tabs the shell knows about. The publish button isn't one of them —
/// it pushes a route rather than swapping a tab, so it has no business in
/// an enum of things that can be "selected".
enum S8llTab { home, drops, chat, profile }

/// The floating bottom bar: four destinations around a lime publish button
/// that sits proud of the bar.
///
/// It floats over the page rather than pushing it up, so every screen
/// underneath has to reserve [S8llBottomNavBar.clearance] at the end of its
/// scroll — otherwise the last row of a feed, or the Publish button on the
/// sell sheet, ends up permanently underneath it.
class S8llBottomNavBar extends StatelessWidget {
  const S8llBottomNavBar({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onPublish,
  });

  /// Bottom padding a scrolling screen needs so its last element clears
  /// the bar and the publish button's overhang.
  static const clearance = 120.0;

  final S8llTab current;
  final ValueChanged<S8llTab> onSelect;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: S8llColors.charcoal,
        border: Border(top: BorderSide(color: S8llColors.divider, width: 0.5)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                tab: S8llTab.home,
                current: current,
                onSelect: onSelect,
              ),
              _NavItem(
                icon: Icons.local_fire_department_rounded,
                label: 'Drops',
                tab: S8llTab.drops,
                current: current,
                onSelect: onSelect,
              ),
              _PublishButton(onTap: onPublish),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Chat',
                tab: S8llTab.chat,
                current: current,
                onSelect: onSelect,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                tab: S8llTab.profile,
                current: current,
                onSelect: onSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.tab,
    required this.current,
    required this.onSelect,
  });

  final IconData icon;
  final String label;
  final S8llTab tab;
  final S8llTab current;
  final ValueChanged<S8llTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = tab == current;
    final color = selected ? S8llColors.lime : S8llColors.greyLow;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: () => onSelect(tab),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Sell something',
      child: GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: const Offset(0, -16),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: S8llColors.lime,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: S8llColors.lime.withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: S8llColors.black, size: 32),
          ),
        ),
      ),
    );
  }
}
