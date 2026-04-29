import 'package:flutter/material.dart';
import '../data/models/debt_model.dart';
import '../data/models/payment_model.dart';
import '../data/services/db_service.dart';

class DebtProvider extends ChangeNotifier {
  // =========================
  // STATE
  // =========================
  List<DebtModel> _debts = [];

  List<DebtModel> get debts => _debts;

  // =========================
  // LOAD DATA (INIT APP)
  // =========================
  Future<void> loadDebts() async {
    final debtMaps = await DBService.instance.getAllDebts();

    List<DebtModel> tempList = [];

    for (var debtMap in debtMaps) {
      final debt = DebtModel.fromMap(debtMap);

      //Ambil semua pembayaran berdasarkan debtId
      final paymentMaps = await DBService.instance.getPaymentsByDebt(debt.id!);

      final payments = paymentMaps.map((e) => PaymentModel.fromMap(e)).toList();

      //Gabungkan debt + payments
      final fullDebt = DebtModel(
        id: debt.id,
        title: debt.title,
        totalAmount: debt.totalAmount,
        dueDate: debt.dueDate,
        payments: payments,
      );

      tempList.add(fullDebt);
    }

    _debts = tempList;
    notifyListeners(); // update UI
  }

  // =========================
  // TAMBAH DATA HUTANG
  // =========================
  Future<void> addDebt({
    required String title,
    required double totalAmount,
    required DateTime dueDate,
  }) async {
    final newDebt = DebtModel(
      title: title,
      totalAmount: totalAmount,
      dueDate: dueDate,
    );

    await DBService.instance.insertDebt(newDebt.toMap());

    await loadDebts(); // refresh data
  }

  Future<void> updateDebt({
    required int id,
    required String title,
    required double totalAmount,
    required DateTime dueDate,
  }) async {
    // cari data hutang lama
    final debt = _debts.firstWhere((item) => item.id == id);

    // validasi total baru tidak boleh
    // lebih kecil dari total dibayar
    if (totalAmount < debt.totalPaid) {
      throw Exception(
        "Total hutang tidak boleh lebih kecil dari jumlah yang sudah dibayar (${debt.totalPaid.toStringAsFixed(0)})",
      );
    }

    await DBService.instance.updateDebt(
      id: id,
      title: title,
      totalAmount: totalAmount,
      dueDate: dueDate,
    );

    await loadDebts();
    notifyListeners();
  }

  // =========================
  // TAMBAH PEMBAYARAN
  // =========================
  Future<void> addPayment({
    required int debtId,
    required double amount,
    required DateTime date,
  }) async {
    final payment = PaymentModel(debtId: debtId, amount: amount, date: date);

    await DBService.instance.insertPayment(payment.toMap());

    await loadDebts(); //auto update progress
  }

  // =========================
  // HAPUS PEMBAYARAN
  // =========================

  Future<void> deletePayment(int id) async {
    await DBService.instance.deletePayment(id);

    await loadDebts();
    notifyListeners();
  }

  // =========================
  // HAPUS HUTANG + PAYMENTS
  // =========================
  Future<void> deleteDebt(int id) async {
    await DBService.instance.deleteDebt(id);

    await loadDebts();
    notifyListeners();
  }

  // =========================
  // GET TOTAL SEMUA HUTANG
  // =========================
  double get totalAllDebt {
    return _debts.fold(0, (sum, item) => sum + item.totalAmount);
  }

  // =========================
  // GET TOTAL SUDAH DIBAYAR
  // =========================
  double get totalAllPaid {
    return _debts.fold(0, (sum, item) => sum + item.totalPaid);
  }

  // =========================
  // GET TOTAL SISA HUTANG
  // =========================
  double get totalAllRemaining {
    return _debts.fold(0, (sum, item) => sum + item.remaining);
  }
}
