import 'package:shared_preferences/shared_preferences.dart';

/// Whether this device has been through the onboarding.
///
/// Device-local, like the theme preference — it's about what this phone has
/// already been shown, not about the account, so it deliberately never
/// touches Firestore. Signing out doesn't replay the introduction.
class FirstRun {
  const FirstRun._();

  static const _onboardingKey = 'hasSeenOnboarding';

  static Future<bool> hasSeenOnboarding() async {
    try {
      return await SharedPreferencesAsync().getBool(_onboardingKey) ?? false;
    } catch (_) {
      // Storage being unavailable shouldn't wedge the app on the splash.
      // Treating it as "seen" skips a re-run of the introduction rather
      // than trapping someone in it every launch.
      return true;
    }
  }

  static Future<void> markOnboardingSeen() async {
    try {
      await SharedPreferencesAsync().setBool(_onboardingKey, true);
    } catch (_) {
      // Best effort; the worst case is seeing the introduction twice.
    }
  }
}
