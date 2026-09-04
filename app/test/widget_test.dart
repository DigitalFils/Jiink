import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:s8ll/main.dart';

void main() {
  Future<void> useTallScreen(WidgetTester tester) async {
    final view = tester.view;
    view.physicalSize = const Size(800, 2000);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

  testWidgets('Feed shows seeded listings with countdown badges', (WidgetTester tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(const S8llApp());
    await tester.pumpAndSettle();

    expect(find.text('S8LL'), findsOneWidget);
    expect(find.textContaining('Nike Air Max 90'), findsOneWidget);
    expect(find.textContaining('h left'), findsWidgets);
  });

  testWidgets('Tapping a listing opens its detail screen', (WidgetTester tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(const S8llApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Nike Air Max 90').first);
    await tester.pumpAndSettle();

    expect(find.text('Message seller'), findsOneWidget);
  });

  testWidgets('Messaging a seller shows the message in the thread', (WidgetTester tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(const S8llApp());
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Nike Air Max 90').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message seller'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Still available?');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Still available?'), findsOneWidget);
  });

  testWidgets('Bottom nav switches between Feed, Messages and Profile', (WidgetTester tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(const S8llApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Your listings'), findsOneWidget);

    await tester.tap(find.text('Messages'));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet'), findsOneWidget);
  });
}
