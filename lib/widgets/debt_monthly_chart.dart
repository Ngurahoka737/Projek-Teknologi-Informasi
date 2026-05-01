import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/debt_model.dart';

enum PeriodType {
  sixMonths(6, '6 bulan'),
  oneYear(12, '1 tahun'),
  threeYears(36, '3 tahun'),
  fiveYears(60, '5 tahun'),
  tenYears(120, '10 tahun');

  final int months;
  final String label;

  const PeriodType(this.months, this.label);
}

class DebtMonthlyChart extends StatefulWidget {
  const DebtMonthlyChart({super.key, required this.debts});

  final List<DebtModel> debts;

  @override
  State<DebtMonthlyChart> createState() => _DebtMonthlyChartState();
}

class _DebtMonthlyChartState extends State<DebtMonthlyChart> {
  PeriodType _selectedPeriod = PeriodType.sixMonths;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final buckets = _buildBuckets(widget.debts, _selectedPeriod.months);
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
                _selectedPeriod.label,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xff6b7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PeriodType.values
                  .map(
                    (period) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(period.label),
                        selected: _selectedPeriod == period,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPeriod = period;
                            });
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: buckets.isEmpty
                  ? _emptyChart(textTheme, colors)
                  : _buildLineChart(buckets, maxY, colors, textTheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChart(TextTheme textTheme, ColorScheme colors) {
    final message = _selectedPeriod == PeriodType.sixMonths
        ? 'Belum ada cicilan di 6 bulan ke depan'
        : 'Belum ada cicilan di ${_selectedPeriod.label} ke depan';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            color: colors.primary.withValues(alpha: 0.4),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xff6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(
    List<_MonthBucket> buckets,
    double maxY,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    final spots = buckets.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.total);
    }).toList();

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    final index = spot.x.toInt();
                    if (index < 0 || index >= buckets.length) {
                      return null;
                    }
                    return LineTooltipItem(
                      _shortCompact(spot.y),
                      TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: const Color(0xffe5e7eb), strokeWidth: 1);
          },
          horizontalInterval: maxY / 4,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
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
                  padding: const EdgeInsets.only(top: 8),
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
        borderData: FlBorderData(show: false),
        maxY: maxY,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            color: colors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 12,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: colors.primary,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colors.primary.withValues(alpha: 0.15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.primary.withValues(alpha: 0.25),
                  colors.primary.withValues(alpha: 0.02),
                ],
              ),
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

  List<_MonthBucket> _buildBuckets(List<DebtModel> debts, int numberOfMonths) {
    if (debts.isEmpty) return [];

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(start.year, start.month + numberOfMonths, 1);
    final months = List.generate(numberOfMonths, (index) {
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
          months[index].total += debt.amountForIndex(i);
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
