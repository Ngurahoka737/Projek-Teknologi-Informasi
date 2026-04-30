import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/debt_model.dart';

class DebtMonthlyChart extends StatelessWidget {
  const DebtMonthlyChart({super.key, required this.debts});

  final List<DebtModel> debts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final buckets = _buildBuckets(debts);
    final maxValue = buckets.fold<double>(0, (sum, item) {
      if (item.total > sum) return item.total;
      return sum;
    });

    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grafik Hutang Bulanan',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '6 bulan ke depan',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xff6b7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 190,
            child: buckets.isEmpty
                ? _emptyChart(textTheme, colors)
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: const Color(0xffe5e7eb),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _shortCompact(value),
                                style: textTheme.labelSmall?.copyWith(
                                  color: const Color(0xff6b7280),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= buckets.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  buckets[index].label,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: const Color(0xff6b7280),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(buckets.length, (index) {
                        final item = buckets[index];
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: item.total,
                              color: colors.primary,
                              width: 14,
                              borderRadius: BorderRadius.circular(10),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: colors.primary.withOpacity(0.08),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(TextTheme textTheme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            color: colors.primary.withOpacity(0.4),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada cicilan di 6 bulan ke depan',
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xff6b7280),
            ),
          ),
        ],
      ),
    );
  }

  String _shortCompact(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}Jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}Rb';
    }
    return value.toStringAsFixed(0);
  }

  List<_MonthBucket> _buildBuckets(List<DebtModel> debts) {
    if (debts.isEmpty) return [];

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(start.year, start.month + 6, 1);
    final months = List.generate(6, (index) {
      final date = DateTime(start.year, start.month + index, 1);
      return _MonthBucket(date: date, total: 0, label: _monthLabel(date));
    });

    for (final debt in debts) {
      final base = DateTime(debt.dueDate.year, debt.dueDate.month, 1);
      for (var i = 0; i < debt.months; i++) {
        final date = DateTime(base.year, base.month + i, 1);
        if (date.isBefore(start) || !date.isBefore(end)) {
          continue;
        }

        final index = _monthDiff(start, date);
        if (index >= 0 && index < months.length) {
          months[index].total += debt.monthlyAmount;
        }
      }
    }

    return months;
  }

  String _monthLabel(DateTime date) {
    final formatter = DateFormat('MMM', 'id_ID');
    return formatter.format(date);
  }

  int _monthDiff(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }
}

class _MonthBucket {
  _MonthBucket({required this.date, required this.total, required this.label});

  final DateTime date;
  final String label;
  double total;
}
