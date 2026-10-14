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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAD0QOEb8j66YIxxPOow38rJotbeShF-o4',
    appId: '1:752189000459:web:30b5639c97e3becbea700e',
    messagingSenderId: '752189000459',
    projectId: 'pointspend',
    authDomain: 'pointspend.firebaseapp.com',
    storageBucket: 'pointspend.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAD0QOEb8j66YIxxPOow38rJotbeShF-o4',
    appId: '1:752189000459:android:30b5639c97e3becbea700e',
    messagingSenderId: '752189000459',
    projectId: 'pointspend',
    storageBucket: 'pointspend.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAD0QOEb8j66YIxxPOow38rJotbeShF-o4',
    appId: '1:752189000459:ios:30b5639c97e3becbea700e',
    messagingSenderId: '752189000459',
    projectId: 'pointspend',
    storageBucket: 'pointspend.firebasestorage.app',
    iosBundleId: 'com.example.pointspend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAD0QOEb8j66YIxxPOow38rJotbeShF-o4',
    appId: '1:752189000459:ios:30b5639c97e3becbea700e',
    messagingSenderId: '752189000459',
    projectId: 'pointspend',
    storageBucket: 'pointspend.firebasestorage.app',
    iosBundleId: 'com.example.pointspend',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAD0QOEb8j66YIxxPOow38rJotbeShF-o4',
    appId: '1:752189000459:web:30b5639c97e3becbea700e',
    messagingSenderId: '752189000459',
    projectId: 'pointspend',
    authDomain: 'pointspend.firebaseapp.com',
    storageBucket: 'pointspend.firebasestorage.app',
  );
}
