// Firebase config for the s8ll-6ab35 project (console.firebase.google.com).
//
// Generated from android/app/google-services.json — if the Firebase project
// is ever recreated or a new Android app registered under it, regenerate
// this by running, from `app/`:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
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
    apiKey: 'AIzaSyBwGP27a1KNo61d-f7j67q8FUGrPrevKhM',
    appId: '1:871773864711:android:8111a7c0b680ecfff5bba2',
    messagingSenderId: '871773864711',
    projectId: 's8ll-6ab35',
    storageBucket: 's8ll-6ab35.firebasestorage.app',
  );
}
