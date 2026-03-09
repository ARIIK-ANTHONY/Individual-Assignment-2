// Firebase options for Kigali City app.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web is not configured for Firebase.');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('This platform is not configured for Firebase.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBv1VIZS7wDVejar8nCaHeWbD3KoXMw-E0',
    appId: '1:871964697095:android:8bca4e3da3134e1f0b40a2',
    messagingSenderId: '871964697095',
    projectId: 'kigali-city-app-10857',
    storageBucket: 'kigali-city-app-10857.firebasestorage.app',
  );
}
