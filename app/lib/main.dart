import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/root_shell.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  runApp(const S8llApp());
}

class S8llApp extends StatelessWidget {
  const S8llApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'S8LL',
        debugShowCheckedModeBanner: false,
        theme: buildS8llTheme(),
        home: const RootShell(),
      ),
    );
  }
}
