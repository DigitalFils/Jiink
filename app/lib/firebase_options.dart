// Placeholder Firebase config — S8LL has no live Firebase project yet.
//
// Once you've created one (console.firebase.google.com) and upgraded it to
// the Blaze plan, replace this whole file by running, from `app/`:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// That command overwrites this file with your project's real values and
// wires up android/app/google-services.json automatically. Until then the
// app compiles and analyzes fine, but Firebase.initializeApp() will fail
// at runtime because these values aren't real.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('S8LL does not support the web platform.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'S8LL only targets Android — run `flutterfire configure` to add '
          'other platforms if you need them.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
  );
}
