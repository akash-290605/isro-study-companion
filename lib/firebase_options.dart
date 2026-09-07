// File generated for Firebase configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD0NBixQrHb33tZMJrsydnyssNyGKEU0ew',
    appId: '1:484826214342:web:8a1d289365db65c2daccc7',
    messagingSenderId: '484826214342',
    projectId: 'isro-study-companion-cf08a',
    authDomain: 'isro-study-companion-cf08a.firebaseapp.com',
    storageBucket: 'isro-study-companion-cf08a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0NBixQrHb33tZMJrsydnyssNyGKEU0ew',
    appId: '1:484826214342:android:0d6ce748ef53a1a1f0a1d2',
    messagingSenderId: '484826214342',
    projectId: 'isro-study-companion-cf08a',
    storageBucket: 'isro-study-companion-cf08a.firebasestorage.app',
  );
}
