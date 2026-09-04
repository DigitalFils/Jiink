import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jiink/main.dart';

void main() {
  Future<void> useTallScreen(WidgetTester tester) async {
    final view = tester.view;
    view.physicalSize = const Size(800, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  }

  testWidgets('Dashboard shows chart of accounts, entry form and balance sheet',
      (WidgetTester tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(const JiinkApp());

    expect(find.text('Chart of Accounts'), findsOneWidget);
    expect(find.text('Add Income / Expense'), findsOneWidget);
    expect(find.text('Balance Sheet (simplified)'), findsOneWidget);
    expect(find.text('Cash'), findsAtLeastNWidgets(1));
  });

  testWidgets('Adding an entry updates the balance sheet', (WidgetTester tester) async {
    await useTallScreen(tester);
    await tester.pumpWidget(const JiinkApp());

    await tester.tap(find.text('Date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Sold goods');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '150');

    await tester.tap(find.text('Add Entry'));
    await tester.pumpAndSettle();

    expect(find.text('150.00'), findsOneWidget);
  });
}
