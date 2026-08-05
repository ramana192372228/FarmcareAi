import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB7K4MxsWU0otjdP-WN1og8pGzcoNnxKNg',
    appId: '1:788933995877:web:859629c7a2253309d2c58c',
    messagingSenderId: '788933995877',
    projectId: 'farmcare-ai-82e05',
    authDomain: 'farmcare-ai-82e05.firebaseapp.com',
    storageBucket: 'farmcare-ai-82e05.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB7K4MxsWU0otjdP-WN1og8pGzcoNnxKNg',
    appId: '1:788933995877:android:859629c7a2253309d2c58c',
    messagingSenderId: '788933995877',
    projectId: 'farmcare-ai-82e05',
    storageBucket: 'farmcare-ai-82e05.firebasestorage.app',
  );
}
