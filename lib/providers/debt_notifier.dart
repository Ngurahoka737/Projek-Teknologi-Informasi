import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/debt_model.dart';
import '../data/models/payment_model.dart';
import '../data/services/db_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/firebase_bootstrap.dart';
import '../data/services/session_service.dart';

class DebtNotifier extends StateNotifier<List<DebtModel>> {
  DebtNotifier() : super([]) {
    loadDebts();
  }

  final FirestoreService _firestoreService = FirestoreService();
  final SessionService _sessionService = SessionService();

  User? get _currentUser {
    if (!FirebaseBootstrap.isAvailable) return null;
    return FirebaseAuth.instance.currentUser;
  }

  bool get _canSync => _currentUser != null;

  Future<List<DebtModel>> _loadLocalDebts() async {
    final debtMaps = await DBService.instance.getAllDebts();

    List<DebtModel> tempList = [];

    for (var debtMap in debtMaps) {
      final debt = DebtModel.fromMap(debtMap);

      final paymentMaps = await DBService.instance.getPaymentsByDebt(debt.id!);
      final payments = paymentMaps.map((e) => PaymentModel.fromMap(e)).toList();

      final fullDebt = DebtModel(
        id: debt.id,
        title: debt.title,
        months: debt.months,
        monthlyAmount: debt.monthlyAmount,
        monthlySchedule: debt.monthlySchedule,
        dueDay: debt.dueDay,
        dueDate: debt.dueDate,
        payments: payments,
      );

      tempList.add(fullDebt);
    }

    return tempList;
  }

  Future<void> _replaceLocalDebts(List<DebtModel> debts) async {
    await DBService.instance.clearAll();

    for (final debt in debts) {
      await DBService.instance.upsertDebt(debt.toMap());

      for (final payment in debt.payments) {
        await DBService.instance.upsertPayment(payment.toMap());
      }
    }
  }

  Future<void> _ensureUserContext() async {
    final uid = _currentUser?.uid;
    final lastUid = await _sessionService.getLastUid();

    await DBService.instance.configureForUser(uid);

    if (uid != lastUid) {
      await DBService.instance.clearAll();
      await _sessionService.setLastUid(uid);
    }
  }

  Future<List<DebtModel>> _loadDebtsCloudFirst() async {
    final user = _currentUser;
    if (user == null) {
      return _loadLocalDebts();
    }

    final remoteDebts = await _firestoreService.getAllDebts(user.uid);
    if (remoteDebts.isNotEmpty) {
      await _replaceLocalDebts(remoteDebts);
      return remoteDebts;
    }

    final localDebts = await _loadLocalDebts();
    if (localDebts.isNotEmpty) {
      await _firestoreService.upsertDebts(user.uid, localDebts);
      return localDebts;
    }

    return [];
  }

  Future<void> loadDebts() async {
    await _ensureUserContext();

    if (_canSync) {
      state = await _loadDebtsCloudFirst();
      return;
    }

    state = await _loadLocalDebts();
  }

  Future<void> addDebt({
    required String title,
    required int months,
    required double monthlyAmount,
    List<double>? monthlySchedule,
    required int dueDay,
    required DateTime dueDate,
  }) async {
    await _ensureUserContext();
    final normalizedMonthlyAmount =
        monthlySchedule != null && monthlySchedule.isNotEmpty
        ? monthlySchedule.fold(0.0, (sum, item) => sum + item) /
              monthlySchedule.length
        : monthlyAmount;
    final totalAmount = monthlySchedule != null && monthlySchedule.isNotEmpty
        ? monthlySchedule.fold(0.0, (sum, item) => sum + item)
        : months * monthlyAmount;
    final newDebt = DebtModel(
      title: title,
      months: months,
      monthlyAmount: normalizedMonthlyAmount,
      monthlySchedule: monthlySchedule,
      dueDay: dueDay,
      dueDate: dueDate,
    );

    final debtId = await DBService.instance.insertDebt(newDebt.toMap());
    final storedDebt = DebtModel(
      id: debtId,
      title: title,
      months: months,
      monthlyAmount: normalizedMonthlyAmount,
      monthlySchedule: monthlySchedule,
      dueDay: dueDay,
      dueDate: dueDate,
    );

    if (_canSync) {
      await _firestoreService.upsertDebt(_currentUser!.uid, storedDebt);
    }

    await loadDebts();
  }

  Future<void> addPayment({
    required int debtId,
    required double amount,
    required DateTime date,
  }) async {
    await _ensureUserContext();
    final payment = PaymentModel(debtId: debtId, amount: amount, date: date);

    final paymentId = await DBService.instance.insertPayment(payment.toMap());
    final storedPayment = PaymentModel(
      id: paymentId,
      debtId: debtId,
      amount: amount,
      date: date,
    );

    if (_canSync) {
      await _firestoreService.upsertPayment(_currentUser!.uid, storedPayment);
    }

    await loadDebts();
  }

  Future<void> deletePayment({
    required int debtId,
    required int paymentId,
  }) async {
    await _ensureUserContext();
    await DBService.instance.deletePayment(paymentId);

    if (_canSync) {
      await _firestoreService.deletePayment(
        _currentUser!.uid,
        debtId,
        paymentId,
      );
    }

    await loadDebts();
  }

  Future<void> deleteDebt(int id) async {
    await _ensureUserContext();
    await DBService.instance.deleteDebt(id);

    if (_canSync) {
      await _firestoreService.deleteDebt(_currentUser!.uid, id);
    }

    await loadDebts();
  }

  Future<void> updateDebt({
    required int id,
    required String title,
    required int months,
    required double monthlyAmount,
    List<double>? monthlySchedule,
    required int dueDay,
    required DateTime dueDate,
  }) async {
    await _ensureUserContext();
    final normalizedMonthlyAmount =
        monthlySchedule != null && monthlySchedule.isNotEmpty
        ? monthlySchedule.fold(0.0, (sum, item) => sum + item) /
              monthlySchedule.length
        : monthlyAmount;
    final totalAmount = monthlySchedule != null && monthlySchedule.isNotEmpty
        ? monthlySchedule.fold(0.0, (sum, item) => sum + item)
        : months * monthlyAmount;
    final debt = state.firstWhere((item) => item.id == id);
    if (totalAmount < debt.totalPaid) {
      throw Exception(
        'Total hutang tidak boleh lebih kecil dari jumlah yang sudah dibayar (${debt.totalPaid.toStringAsFixed(0)})',
      );
    }

    await DBService.instance.updateDebt(
      id: id,
      title: title,
      totalAmount: totalAmount,
      months: months,
      monthlyAmount: normalizedMonthlyAmount,
      monthlySchedule: monthlySchedule,
      dueDay: dueDay,
      dueDate: dueDate,
    );

    if (_canSync) {
      final updatedDebt = DebtModel(
        id: id,
        title: title,
        months: months,
        monthlyAmount: normalizedMonthlyAmount,
        monthlySchedule: monthlySchedule,
        dueDay: dueDay,
        dueDate: dueDate,
      );
      await _firestoreService.upsertDebt(_currentUser!.uid, updatedDebt);
    }

    await loadDebts();
  }
}

final debtNotifierProvider =
    StateNotifierProvider<DebtNotifier, List<DebtModel>>(
      (ref) => DebtNotifier(),
    );
