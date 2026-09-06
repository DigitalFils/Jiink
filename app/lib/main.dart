import 'dart:async';

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
import 'state/theme_controller.dart';
import 'theme.dart';

// Stripe test-mode publishable key for the s8ll-6ab35 project's Connect
// integration (dashboard.stripe.com/test/apikeys). Publishable keys are
// safe to ship in client code — only the secret key needs protecting,
// and that one lives in Firebase Functions secrets, not here.
const _stripePublishableKey = 'pk_test_uNWcnUhznC2cD3nys85JsCaN';

void main() {
  // A release build (which every sideloaded APK here is) shows no visible
  // error at all by default when something throws — no red screen, nothing
  // in Logcat the user can reach. Route every failure, startup or later, to
  // an on-screen message instead, so a failure in the field is diagnosable
  // from a screenshot rather than indistinguishable from a hang.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        runApp(_StartupErrorApp(error: details.exception, stackTrace: details.stack ?? StackTrace.current));
      };

      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
            .timeout(const Duration(seconds: 15), onTimeout: () => throw Exception('Firebase.initializeApp() timed out'));
        Stripe.publishableKey = _stripePublishableKey;
        await Stripe.instance.applySettings().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Stripe.instance.applySettings() timed out'),
        );
      } catch (error, stackTrace) {
        runApp(_StartupErrorApp(error: error, stackTrace: stackTrace));
        return;
      }
      runApp(const S8llApp());
    },
    (error, stackTrace) => runApp(_StartupErrorApp(error: error, stackTrace: stackTrace)),
  );
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error, required this.stackTrace});

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'S8LL failed to start',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('$error', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 16),
                  Text('$stackTrace', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class S8llApp extends StatelessWidget {
  const S8llApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => PaymentsService()),
        Provider(create: (_) => ChatRepository()),
        Provider(create: (_) => ListingsRepository()),
        Provider(create: (_) => ReviewsRepository()),
        Provider(create: (_) => OffersRepository()),
        Provider(create: (_) => SavedSearchesRepository()),
        Provider(create: (_) => TrustSafetyRepository()),
      ],
      child: const _AuthGate(),
    );
  }
}

/// Decides, then builds, the whole [MaterialApp] — rather than sitting
/// inside a fixed MaterialApp's `home:`, so that a signed-in [AppState] can
/// wrap the MaterialApp itself. A Navigator's pushed routes (chat threads,
/// listing detail, publish) are siblings in its Overlay, not descendants of
/// whatever `home:` rendered; a provider placed only around `home:` is
/// invisible to them, which is exactly the "Provider<AppState> not found"
/// crash that hit every pushed screen reading AppState. Wrapping MaterialApp
/// itself makes it an ancestor of the Overlay, and so of every route in it.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildApp(
            home: const Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return _buildApp(home: AuthScreen(authService: authService));
        }
        return ChangeNotifierProvider<AppState>(
          key: ValueKey(user.uid),
          create: (_) => AppState(uid: user.uid),
          child: _buildApp(home: const _PushNotificationRegistrar(child: RootShell())),
        );
      },
    );
  }

  Widget _buildApp({required Widget home}) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          title: 'S8LL',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.mode,
          theme: buildS8llTheme(brightness: Brightness.light),
          darkTheme: buildS8llTheme(),
          home: home,
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
