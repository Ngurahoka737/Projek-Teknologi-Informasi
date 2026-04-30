import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static const _incomeKey = 'monthly_income';

  String _keyForUid(String? uid) {
    if (uid == null || uid.isEmpty) {
      return '${_incomeKey}_guest';
    }

    final safeUid = uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${_incomeKey}_$safeUid';
  }

  Future<double?> getMonthlyIncome(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyForUid(uid));
  }

  Future<void> setMonthlyIncome(String? uid, double income) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyForUid(uid), income);
  }
}
