import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

void main() {
  runApp(const JiinkApp());
}

class JiinkApp extends StatelessWidget {
  const JiinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jiink Accounting Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}
