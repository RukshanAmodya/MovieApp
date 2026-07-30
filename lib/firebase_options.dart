// File generated manually from original google-services.json config
// Project: rooflix-app

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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3eo55U9kgJA3m_XIEMmMJfGLK4TXnLRw',
    appId: '1:110749291342:android:161e211414c15350e9441f',
    messagingSenderId: '110749291342',
    projectId: 'rooflix-app',
    databaseURL: 'https://rooflix-app-default-rtdb.firebaseio.com',
    storageBucket: 'rooflix-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3eo55U9kgJA3m_XIEMmMJfGLK4TXnLRw',
    appId: '1:110749291342:ios:161e211414c15350e9441f',
    messagingSenderId: '110749291342',
    projectId: 'rooflix-app',
    databaseURL: 'https://rooflix-app-default-rtdb.firebaseio.com',
    storageBucket: 'rooflix-app.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC3eo55U9kgJA3m_XIEMmMJfGLK4TXnLRw',
    appId: '1:110749291342:macos:161e211414c15350e9441f',
    messagingSenderId: '110749291342',
    projectId: 'rooflix-app',
    databaseURL: 'https://rooflix-app-default-rtdb.firebaseio.com',
    storageBucket: 'rooflix-app.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC3eo55U9kgJA3m_XIEMmMJfGLK4TXnLRw',
    appId: '1:110749291342:web:161e211414c15350e9441f',
    messagingSenderId: '110749291342',
    projectId: 'rooflix-app',
    databaseURL: 'https://rooflix-app-default-rtdb.firebaseio.com',
    storageBucket: 'rooflix-app.firebasestorage.app',
    authDomain: 'rooflix-app.firebaseapp.com',
  );
}
