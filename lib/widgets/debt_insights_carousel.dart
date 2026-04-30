import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/debt_model.dart';
import 'debt_monthly_chart.dart';

class DebtInsightsCarousel extends StatefulWidget {
  const DebtInsightsCarousel({
    super.key,
    required this.debts,
    required this.monthlyIncome,
  });

  final List<DebtModel> debts;
  final double? monthlyIncome;

  @override
  State<DebtInsightsCarousel> createState() => _DebtInsightsCarouselState();
}

class _DebtInsightsCarouselState extends State<DebtInsightsCarousel> {
  late final PageController _pageController;
  Timer? _timer;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final nextIndex = (_pageIndex + 1) % 2;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _pageIndex = index;
              });
            },
            children: [
              DebtMonthlyChart(debts: widget.debts),
              DebtRatioCard(
                debts: widget.debts,
                monthlyIncome: widget.monthlyIncome,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            final isActive = index == _pageIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 14 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xffd1d5db),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class DebtRatioCard extends StatelessWidget {
  const DebtRatioCard({
    super.key,
    required this.debts,
    required this.monthlyIncome,
  });

  final List<DebtModel> debts;
  final double? monthlyIncome;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final totalRemaining = debts.fold<double>(
      0,
      (sum, item) => sum + item.remaining,
    );
    final monthlyObligation = debts
        .where((item) => item.remaining > 0)
        .fold<double>(0, (sum, item) => sum + item.monthlyAmount);

    final income = (monthlyIncome ?? 0).toDouble();
    final ratio = income > 0 ? (monthlyObligation / income) : 0.0;
    final ratioPercent = (ratio * 100).toStringAsFixed(0);
    final clamped = ratio.clamp(0.0, 1.0).toDouble();

    Color ratioColor;
    if (ratio >= 0.7) {
      ratioColor = const Color(0xffdc2626);
    } else if (ratio >= 0.4) {
      ratioColor = const Color(0xfff59e0b);
    } else {
      ratioColor = const Color(0xff16a34a);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rasio Hutang',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (income <= 0)
            Text(
              'Isi penghasilan di Profil untuk melihat rasio.',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xff6b7280),
              ),
            )
          else
            Text(
              '$ratioPercent% dari penghasilan bulanan',
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xff6b7280),
              ),
            ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: clamped,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            color: ratioColor,
            backgroundColor: colors.primary.withOpacity(0.08),
          ),
          const SizedBox(height: 16),
          _infoRow(
            'Cicilan / bulan',
            rupiah.format(monthlyObligation),
            textTheme,
          ),
          const SizedBox(height: 6),
          _infoRow('Sisa hutang', rupiah.format(totalRemaining), textTheme),
          const SizedBox(height: 6),
          _infoRow(
            'Penghasilan',
            income <= 0 ? '-' : rupiah.format(income),
            textTheme,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.bodySmall?.copyWith(color: const Color(0xff6b7280)),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
