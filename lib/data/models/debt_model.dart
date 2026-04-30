import 'payment_model.dart';

class DebtModel {
  final int? id;
  final String title;
  final int months;
  final double monthlyAmount;
  final int dueDay;
  final DateTime dueDate;
  final List<PaymentModel> payments;

  DebtModel({
    this.id,
    required this.title,
    required this.months,
    required this.monthlyAmount,
    required this.dueDay,
    required this.dueDate,
    this.payments = const [],
  });

  double get totalAmount {
    return monthlyAmount * months;
  }

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
      'months': months,
      'monthlyAmount': monthlyAmount,
      'dueDay': dueDay,
      'dueDate': dueDate.toIso8601String(),
    };
  }

  // Convert dari Map (database → object)
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    final dueDateRaw = map['dueDate'];
    final parsedDueDate = dueDateRaw is String && dueDateRaw.isNotEmpty
        ? DateTime.parse(dueDateRaw)
        : DateTime.now();

    return DebtModel(
      id: map['id'],
      title: map['title'],
      months: (map['months'] as int?) ?? 1,
      monthlyAmount:
          (map['monthlyAmount'] as num?)?.toDouble() ??
          (map['totalAmount'] as num?)?.toDouble() ??
          0,
      dueDay: (map['dueDay'] as int?) ?? parsedDueDate.day,
      dueDate: parsedDueDate,
    );
  }
}
