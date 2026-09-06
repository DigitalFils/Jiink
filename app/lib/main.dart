import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/home/home_screen.dart';
import 'screens/drop/drop_screen.dart';
import 'screens/sell/sell_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  runApp(const S8LLApp());
}

class S8LLApp extends StatelessWidget {
  const S8LLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S8LL Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    DropScreen(),
    SellScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
