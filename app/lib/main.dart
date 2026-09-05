import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/root_shell.dart';
import 'services/auth_service.dart';
import 'services/chat_repository.dart';
import 'services/listings_repository.dart';
import 'services/offers_repository.dart';
import 'services/payments_service.dart';
import 'services/reviews_repository.dart';
import 'services/saved_searches_repository.dart';
import 'services/trust_safety_repository.dart';
import 'state/app_state.dart';
import 'theme.dart';

// TODO: replace with your Stripe *publishable* (not secret) test key from
// the Stripe Dashboard → Developers → API keys, once you have an account.
const _stripePublishableKey = 'pk_test_REPLACE_ME';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Stripe.publishableKey = _stripePublishableKey;
  await Stripe.instance.applySettings();
  runApp(const S8llApp());
}

class S8llApp extends StatelessWidget {
  const S8llApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => PaymentsService()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => ListingsRepository()),
        Provider(create: (_) => ReviewsRepository()),
        Provider(create: (_) => OffersRepository()),
        Provider(create: (_) => SavedSearchesRepository()),
        Provider(create: (_) => TrustSafetyRepository()),
      ],
      child: MaterialApp(
        title: 'S8LL',
        debugShowCheckedModeBanner: false,
        theme: buildS8llTheme(),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          return AuthScreen(authService: authService);
        }
        return ChangeNotifierProvider<AppState>(
          key: ValueKey(user.uid),
          create: (_) => AppState(uid: user.uid),
          child: const _PushNotificationRegistrar(child: RootShell()),
        );
      },
    );
  }
}

/// Requests notification permission and registers this device's FCM token
/// once signed in — a no-op (never throws, never blocks the UI) if the user
/// declines, since push is a nice-to-have, not something the app depends on.
class _PushNotificationRegistrar extends StatefulWidget {
  const _PushNotificationRegistrar({required this.child});

  final Widget child;

  @override
  State<_PushNotificationRegistrar> createState() => _PushNotificationRegistrarState();
}

class _PushNotificationRegistrarState extends State<_PushNotificationRegistrar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _register());
  }

  Future<void> _register() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null && mounted) {
        await context.read<AppState>().registerFcmToken(token);
      }
    } catch (_) {
      // Push is best-effort — a missing/unsupported messaging setup (e.g. no
      // google-services.json configured yet) shouldn't break sign-in.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
