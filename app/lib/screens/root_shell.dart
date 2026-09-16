import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/bottom_nav_bar.dart';
import 'capture_screen.dart';
import 'drops_screen.dart';
import 'feed_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

/// The signed-in app: four tabs behind a floating nav bar, with selling
/// hanging off the middle button as a pushed route rather than a fifth tab.
///
/// The bar floats *over* the content (that's what the lime button's
/// overhang needs), so the body runs full-bleed to the bottom of the screen
/// and each tab reserves [S8llBottomNavBar.clearance] at the end of its own
/// scroll. An IndexedStack keeps scroll position and Firestore listeners
/// alive across tab switches — coming back to the feed shouldn't reload it.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  S8llTab _tab = S8llTab.home;

  static const _screens = [
    FeedScreen(),
    DropsScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _publish() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: S8llColors.black,
      // extendBody so the page paints behind the floating bar instead of
      // stopping short of it and leaving a dead strip.
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(index: _tab.index, children: _screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: S8llBottomNavBar(
              current: _tab,
              onSelect: (tab) => setState(() => _tab = tab),
              onPublish: _publish,
            ),
          ),
        ],
      ),
    );
  }
}
