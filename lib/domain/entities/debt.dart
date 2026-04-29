class Debt {
  final int? id;
  final String title;
  final double totalAmount;
  final DateTime dueDate;

  Debt({
    this.id,
    required this.title,
    required this.totalAmount,
    required this.dueDate,
  });
}
