import 'package:firebase_core/firebase_core.dart';
import 'package:accountable_payment_tracker/firebase_options.dart';

class FirebaseBootstrap {
  static bool _isInitialized = false;
  static bool _isAvailable = false;

  static bool get isAvailable => _isAvailable;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _isAvailable = true;
    } catch (_) {
      _isAvailable = false;
    } finally {
      _isInitialized = true;
    }
  }
}
