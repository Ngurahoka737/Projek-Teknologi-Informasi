import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/insights/debt_health.dart';
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
  static const _pageCount = 3;
  static const _slideInterval = Duration(seconds: 6);
  static const _pauseDuration = Duration(seconds: 10);

  late final PageController _pageController;
  Timer? _timer;
  int _pageIndex = 0;
  DateTime? _pausedUntil;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(_slideInterval, (_) {
      if (!mounted) return;
      if (_isPaused()) return;

      final nextIndex = (_pageIndex + 1) % _pageCount;
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

  bool _isPaused() {
    final until = _pausedUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  void _pauseAutoSlide() {
    _pausedUntil = DateTime.now().add(_pauseDuration);
  }

  @override
  Widget build(BuildContext context) {
    final health = calculateDebtHealth(widget.debts);
    final pages = [
      DebtMonthlyChart(debts: widget.debts),
      DebtRatioCard(debts: widget.debts, monthlyIncome: widget.monthlyIncome),
      DebtHealthCard(health: health),
    ];

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _pageIndex = index;
              });
            },
            children: pages
                .map(
                  (child) => GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _pauseAutoSlide,
                    child: child,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pageCount, (index) {
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
        .fold<double>(0, (sum, item) => sum + item.monthlyAverage);

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

class DebtHealthCard extends StatelessWidget {
  const DebtHealthCard({super.key, required this.health});

  final DebtHealthResult health;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final healthColor = _healthColor(health.status);

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
            'Index Kesehatan Hutang',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${health.score} / 100',
                  style: textTheme.labelMedium?.copyWith(
                    color: healthColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                health.status,
                style: textTheme.labelMedium?.copyWith(
                  color: healthColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            health.insight,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xff6b7280),
            ),
          ),
        ],
      ),
    );
  }

  Color _healthColor(String status) {
    switch (status) {
      case 'Bahaya':
        return const Color(0xffdc2626);
      case 'Waspada':
        return const Color(0xfff59e0b);
      default:
        return const Color(0xff16a34a);
    }
  }
}
