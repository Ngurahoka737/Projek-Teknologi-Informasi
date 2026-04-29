import 'payment_model.dart';

class DebtModel {
  final int? id;
  final String title;
  final double totalAmount;
  final DateTime dueDate;
  final List<PaymentModel> payments;

  DebtModel({
    this.id,
    required this.title,
    required this.totalAmount,
    required this.dueDate,
    this.payments = const [],
  });

  //Hitung total pembayaran
  double get totalPaid {
    return payments.fold(0, (sum, item) => sum + item.amount);
  }

  //Hitung sisa hutang
  double get remaining {
    return totalAmount - totalPaid;
  }

  //Progress (0 - 1)
  double get progress {
    if (totalAmount == 0) return 0;
    return totalPaid / totalAmount;
  }

  // Convert ke Map (untuk database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  // Convert dari Map (database → object)
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'],
      title: map['title'],
      totalAmount: map['totalAmount'],
      dueDate: DateTime.parse(map['dueDate']),
    );
  }
}
