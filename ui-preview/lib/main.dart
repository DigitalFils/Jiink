import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'utils/app_router.dart';

/// S8LL Marketplace — v2.0
///
/// Ultimate blend of Avito x Dewu x PDD x Xiaohongshu.
///
/// v2.0 highlights:
///  * Every navigation goes through [AppRoutes] named routes with the
///    standardized fade + bounce transition from the motion system.
///  * Light theme is fully built and switchable at runtime through
///    [ThemeProvider] (dark stays the default).
void main() {
  runApp(const S8LLApp());
}

class S8LLApp extends StatefulWidget {
  const S8LLApp({super.key});

  @override
  State<S8LLApp> createState() => _S8LLAppState();
}

class _S8LLAppState extends State<S8LLApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeProvider,
      builder: (context, _) => MaterialApp(
        title: 'S8LL Marketplace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeProvider.themeMode,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
