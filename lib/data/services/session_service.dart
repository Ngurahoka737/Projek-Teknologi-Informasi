import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _lastUidKey = 'last_uid';

  Future<String?> getLastUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastUidKey);
  }

  Future<void> setLastUid(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid == null || uid.isEmpty) {
      await prefs.remove(_lastUidKey);
    } else {
      await prefs.setString(_lastUidKey, uid);
    }
  }
}
