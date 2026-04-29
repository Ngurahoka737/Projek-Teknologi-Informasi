class PaymentModel {
  final int? id;
  final int debtId;
  final double amount;
  final DateTime date;

  PaymentModel({
    this.id,
    required this.debtId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'],
      debtId: map['debtId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
