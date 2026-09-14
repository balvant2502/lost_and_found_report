// File generated for CampusFound with user's Firebase project settings.
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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDJicDFaeeSrmetF7z2ZuJ2Se5qe4v3G80',
    appId: '1:1048469287873:web:73452c8f2670d1b4063540',
    messagingSenderId: '1048469287873',
    projectId: 'lost-found-item-report',
    authDomain: 'lost-found-item-report.firebaseapp.com',
    storageBucket: 'lost-found-item-report.firebasestorage.app',
    measurementId: 'G-E0MCH3CKKY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAeRnQUkDQOOug_4KHc74TD55jBPBWqEkw',
    appId: '1:1048469287873:android:ba0acd3960b70955063540',
    messagingSenderId: '1048469287873',
    projectId: 'lost-found-item-report',
    storageBucket: 'lost-found-item-report.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzr1aYZxINyMkmn8PwzMgkKYBiTuaNyBQ',
    appId: '1:1048469287873:ios:8b8db1a2ab130b40063540',
    messagingSenderId: '1048469287873',
    projectId: 'lost-found-item-report',
    storageBucket: 'lost-found-item-report.firebasestorage.app',
    iosBundleId: 'com.example.campusFound',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCzr1aYZxINyMkmn8PwzMgkKYBiTuaNyBQ',
    appId: '1:1048469287873:ios:8b8db1a2ab130b40063540',
    messagingSenderId: '1048469287873',
    projectId: 'lost-found-item-report',
    storageBucket: 'lost-found-item-report.firebasestorage.app',
    iosBundleId: 'com.example.campusFound',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDJicDFaeeSrmetF7z2ZuJ2Se5qe4v3G80',
    appId: '1:1048469287873:web:a974dfed94fbd32b063540',
    messagingSenderId: '1048469287873',
    projectId: 'lost-found-item-report',
    authDomain: 'lost-found-item-report.firebaseapp.com',
    storageBucket: 'lost-found-item-report.firebasestorage.app',
    measurementId: 'G-KMRBVH80M5',
  );
}
