import 'dart:math' as math;

import '../../data/models/debt_model.dart';

class DebtHealthResult {
  const DebtHealthResult({
    required this.score,
    required this.status,
    required this.insight,
  });

  final int score;
  final String status;
  final String insight;
}

DebtHealthResult calculateDebtHealth(List<DebtModel> debts) {
  final activeDebts = debts.where((item) => item.remaining > 0).toList();
  if (activeDebts.isEmpty) {
    return const DebtHealthResult(
      score: 100,
      status: 'Aman',
      insight: 'Tidak ada hutang aktif. Pertahankan kondisi ini.',
    );
  }

  final totalDebt = activeDebts.fold<double>(
    0,
    (sum, item) => sum + item.totalAmount,
  );
  final remainingDebt = activeDebts.fold<double>(
    0,
    (sum, item) => sum + item.remaining,
  );
  final installments = activeDebts.fold<int>(
    0,
    (sum, item) => sum + item.months,
  );

  final totalScore = _logScore(totalDebt, 1e6, 1e10);
  final remainingScore = _logScore(remainingDebt, 1e6, 1e10);
  final installmentScore = _linearScore(installments.toDouble(), 6, 60);

  final weighted =
      (totalScore * 0.4) + (remainingScore * 0.4) + (installmentScore * 0.2);
  final score = (weighted * 100).round().clamp(0, 100);

  if (score >= 70) {
    return DebtHealthResult(
      score: score,
      status: 'Aman',
      insight: 'Beban hutang terkendali. Jaga disiplin bayar cicilan.',
    );
  }
  if (score >= 40) {
    return DebtHealthResult(
      score: score,
      status: 'Waspada',
      insight: 'Mulai berat. Kurangi hutang baru dan prioritaskan pelunasan.',
    );
  }
  return DebtHealthResult(
    score: score,
    status: 'Bahaya',
    insight: 'Beban hutang tinggi. Fokus pelunasan dan evaluasi pengeluaran.',
  );
}

double _logScore(double value, double min, double max) {
  if (value <= min) return 1;
  if (value >= max) return 0;

  final numerator = math.log(value) - math.log(min);
  final denominator = math.log(max) - math.log(min);
  final ratio = (numerator / denominator).clamp(0.0, 1.0);
  return 1 - ratio;
}

double _linearScore(double value, double min, double max) {
  if (value <= min) return 1;
  if (value >= max) return 0;

  final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
  return 1 - ratio;
}
