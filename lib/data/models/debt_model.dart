import 'dart:convert';

import 'payment_model.dart';

class DebtModel {
  final int? id;
  final String title;
  final int months;
  final double monthlyAmount;
  final List<double>? monthlySchedule;
  final int dueDay;
  final DateTime dueDate;
  final List<PaymentModel> payments;

  DebtModel({
    this.id,
    required this.title,
    required this.months,
    required this.monthlyAmount,
    this.monthlySchedule,
    required this.dueDay,
    required this.dueDate,
    this.payments = const [],
  });

  double get totalAmount {
    if (monthlySchedule != null && monthlySchedule!.isNotEmpty) {
      return monthlySchedule!.fold(0.0, (sum, item) => sum + item);
    }
    return monthlyAmount * months;
  }

  double get monthlyAverage {
    if (monthlySchedule != null && monthlySchedule!.isNotEmpty) {
      return monthlySchedule!.fold(0.0, (sum, item) => sum + item) /
          monthlySchedule!.length;
    }
    return monthlyAmount;
  }

  double amountForIndex(int index) {
    if (monthlySchedule == null || monthlySchedule!.isEmpty) {
      return monthlyAmount;
    }
    if (index < 0 || index >= monthlySchedule!.length) {
      return monthlyAverage;
    }
    return monthlySchedule![index];
  }

  //Hitung total pembayaran
  double get totalPaid {
    return payments.fold(0.0, (sum, item) => sum + item.amount);
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
      'schedule': monthlySchedule == null ? null : jsonEncode(monthlySchedule),
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
    final scheduleRaw = map['schedule'];
    List<double>? schedule;
    if (scheduleRaw is String && scheduleRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(scheduleRaw);
        if (decoded is List) {
          schedule = decoded.map((e) => (e as num).toDouble()).toList();
        }
      } catch (_) {
        schedule = null;
      }
    }

    return DebtModel(
      id: map['id'],
      title: map['title'],
      months: (map['months'] as int?) ?? 1,
      monthlyAmount:
          (map['monthlyAmount'] as num?)?.toDouble() ??
          (map['totalAmount'] as num?)?.toDouble() ??
          0,
      monthlySchedule: schedule,
      dueDay: (map['dueDay'] as int?) ?? parsedDueDate.day,
      dueDate: parsedDueDate,
    );
  }
}
