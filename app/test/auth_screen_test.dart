import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:s8ll/screens/auth_screen.dart';
import 'package:s8ll/services/auth_service.dart';

class FakeAuthService implements AuthServiceBase {
  bool signUpCalled = false;
  String? signedUpEmail;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String city,
  }) async {
    signUpCalled = true;
    signedUpEmail = email;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('shows validation errors instead of submitting when fields are empty',
      (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(authService: fakeAuth)));

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsWidgets);
    expect(fakeAuth.signUpCalled, isFalse);
  });

  testWidgets('submits sign-up with the entered details', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(authService: fakeAuth)));

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Jordan');
    await tester.enterText(find.widgetWithText(TextFormField, 'City'), 'Manchester');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'jordan@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'sellfast');

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(fakeAuth.signUpCalled, isTrue);
    expect(fakeAuth.signedUpEmail, 'jordan@example.com');
  });

  testWidgets('toggling switches to the sign-in form', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();
    await tester.pumpWidget(MaterialApp(home: AuthScreen(authService: fakeAuth)));

    expect(find.text('Create account'), findsOneWidget);
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Name'), findsNothing);
  });
}
