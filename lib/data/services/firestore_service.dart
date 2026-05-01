import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/debt_model.dart';
import '../models/payment_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _debtsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('debts');
  }

  CollectionReference<Map<String, dynamic>> _paymentsRef(
    String uid,
    int debtId,
  ) {
    return _debtsRef(uid).doc(debtId.toString()).collection('payments');
  }

  Future<List<DebtModel>> getAllDebts(String uid) async {
    final snapshot = await _debtsRef(uid).get();
    final debts = <DebtModel>[];

    for (final doc in snapshot.docs) {
      final id = int.tryParse(doc.id);
      if (id == null) continue;

      final data = doc.data();
      final payments = await getPayments(uid, id);
      final dueDateRaw = data['dueDate'] as String?;
      final parsedDueDate = dueDateRaw != null && dueDateRaw.isNotEmpty
          ? DateTime.parse(dueDateRaw)
          : DateTime.now();
      final scheduleRaw = data['schedule'];
      List<double>? schedule;
      if (scheduleRaw is List) {
        schedule = scheduleRaw.map((e) => (e as num).toDouble()).toList();
      }

      debts.add(
        DebtModel(
          id: id,
          title: (data['title'] ?? '') as String,
          months: (data['months'] as int?) ?? 1,
          monthlyAmount:
              (data['monthlyAmount'] as num?)?.toDouble() ??
              (data['totalAmount'] as num?)?.toDouble() ??
              0,
          monthlySchedule: schedule,
          dueDay: (data['dueDay'] as int?) ?? parsedDueDate.day,
          dueDate: parsedDueDate,
          payments: payments,
        ),
      );
    }

    debts.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return debts;
  }

  Future<List<PaymentModel>> getPayments(String uid, int debtId) async {
    final snapshot = await _paymentsRef(uid, debtId).get();
    final payments = <PaymentModel>[];

    for (final doc in snapshot.docs) {
      final id = int.tryParse(doc.id);
      if (id == null) continue;

      final data = doc.data();

      payments.add(
        PaymentModel(
          id: id,
          debtId: debtId,
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          date: DateTime.parse(data['date'] as String),
        ),
      );
    }

    payments.sort((a, b) => b.date.compareTo(a.date));
    return payments;
  }

  Future<void> upsertDebt(String uid, DebtModel debt) async {
    final id = debt.id;
    if (id == null) return;

    await _debtsRef(uid).doc(id.toString()).set({
      'title': debt.title,
      'totalAmount': debt.totalAmount,
      'months': debt.months,
      'monthlyAmount': debt.monthlyAmount,
      'schedule': debt.monthlySchedule,
      'dueDay': debt.dueDay,
      'dueDate': debt.dueDate.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertPayment(String uid, PaymentModel payment) async {
    final id = payment.id;
    if (id == null) return;

    await _paymentsRef(uid, payment.debtId).doc(id.toString()).set({
      'amount': payment.amount,
      'date': payment.date.toIso8601String(),
      'debtId': payment.debtId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deletePayment(String uid, int debtId, int paymentId) async {
    await _paymentsRef(uid, debtId).doc(paymentId.toString()).delete();
  }

  Future<void> deleteDebt(String uid, int debtId) async {
    final debtRef = _debtsRef(uid).doc(debtId.toString());
    final paymentsSnap = await debtRef.collection('payments').get();
    final batch = _firestore.batch();

    for (final doc in paymentsSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(debtRef);
    await batch.commit();
  }

  Future<void> upsertDebts(String uid, List<DebtModel> debts) async {
    for (final debt in debts) {
      await upsertDebt(uid, debt);

      for (final payment in debt.payments) {
        await upsertPayment(uid, payment);
      }
    }
  }
}
