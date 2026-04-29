import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/debt_model.dart';
import '../data/models/payment_model.dart';
import '../data/services/db_service.dart';

class DebtNotifier extends StateNotifier<List<DebtModel>> {
  DebtNotifier() : super([]) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    final debtMaps = await DBService.instance.getAllDebts();

    List<DebtModel> tempList = [];

    for (var debtMap in debtMaps) {
      final debt = DebtModel.fromMap(debtMap);

      final paymentMaps = await DBService.instance.getPaymentsByDebt(debt.id!);
      final payments = paymentMaps.map((e) => PaymentModel.fromMap(e)).toList();

      final fullDebt = DebtModel(
        id: debt.id,
        title: debt.title,
        totalAmount: debt.totalAmount,
        dueDate: debt.dueDate,
        payments: payments,
      );

      tempList.add(fullDebt);
    }

    state = tempList;
  }

  Future<void> addDebt({required String title, required double totalAmount, required DateTime dueDate}) async {
    final newDebt = DebtModel(title: title, totalAmount: totalAmount, dueDate: dueDate);
    await DBService.instance.insertDebt(newDebt.toMap());
    await loadDebts();
  }

  Future<void> addPayment({required int debtId, required double amount, required DateTime date}) async {
    final payment = PaymentModel(debtId: debtId, amount: amount, date: date);
    await DBService.instance.insertPayment(payment.toMap());
    await loadDebts();
  }

  Future<void> deletePayment(int id) async {
    await DBService.instance.deletePayment(id);
    await loadDebts();
  }

  Future<void> deleteDebt(int id) async {
    await DBService.instance.deleteDebt(id);
    await loadDebts();
  }

  Future<void> updateDebt({required int id, required String title, required double totalAmount, required DateTime dueDate}) async {
    final debt = state.firstWhere((item) => item.id == id);
    if (totalAmount < debt.totalPaid) {
      throw Exception('Total hutang tidak boleh lebih kecil dari jumlah yang sudah dibayar (${debt.totalPaid.toStringAsFixed(0)})');
    }

    await DBService.instance.updateDebt(id: id, title: title, totalAmount: totalAmount, dueDate: dueDate);
    await loadDebts();
  }
}

final debtNotifierProvider = StateNotifierProvider<DebtNotifier, List<DebtModel>>((ref) => DebtNotifier());
