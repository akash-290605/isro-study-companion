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
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
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
    apiKey: 'AIzaSyBy5MMTOPBzm7cdOkQg2xwDgA1nZmStLWQ',
    appId: '1:484826214342:android:51f6c094a0ff709cdaccc7',
    messagingSenderId: '484826214342',
    projectId: 'isro-study-companion-cf08a',
    storageBucket: 'isro-study-companion-cf08a.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD0NBixQrHb33tZMJrsydnyssNyGKEU0ew',
    appId: '1:484826214342:web:8a1d289365db65c2daccc7',
    messagingSenderId: '484826214342',
    projectId: 'isro-study-companion-cf08a',
    authDomain: 'isro-study-companion-cf08a.firebaseapp.com',
    storageBucket: 'isro-study-companion-cf08a.firebasestorage.app',
  );
}
