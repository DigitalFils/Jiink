import 'package:flutter/material.dart';

import '../theme.dart';
import 'capture_screen.dart';
import 'feed_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  static const _screens = [FeedScreen(), MessagesScreen(), ProfileScreen()];

  void _openCamera() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CaptureScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCamera,
        backgroundColor: S8llColors.lime,
        foregroundColor: S8llColors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: S8llColors.charcoal,
        indicatorColor: S8llColors.lime.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
