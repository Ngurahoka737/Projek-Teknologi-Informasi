import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_notifier.dart';
import '../../widgets/debt_card.dart';
import '../../widgets/debt_insights_carousel.dart';
import '../add_debt/add_debt_screen.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/pdf_service.dart';
import '../../presentation/auth/auth_controller.dart';
import '../../providers/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late final AnimationController _introController;
  late final Animation<double> _summaryFade;
  late final Animation<Offset> _summarySlide;
  late final Animation<double> _insightFade;
  late final Animation<Offset> _insightSlide;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _summaryFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _summarySlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _insightFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.2, 0.9, curve: Curves.easeOut),
    );
    _insightSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _introController,
            curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _introController.forward();
      ref.read(debtNotifierProvider.notifier).loadDebts();
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final debts = ref.watch(debtNotifierProvider);
    final profileState = ref.watch(profileControllerProvider);
    final activeDebts = debts.where((d) => d.remaining > 0).toList();

    final totalAllDebt = debts.fold(0.0, (sum, item) => sum + item.totalAmount);
    final totalAllPaid = debts.fold(0.0, (sum, item) => sum + item.totalPaid);
    final totalAllRemaining = debts.fold(
      0.0,
      (sum, item) => sum + item.remaining,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Debt Manager"),

        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
          // 🔔 TEST NOTIF
          IconButton(
            onPressed: () {
              NotificationService.showNotification(
                id: 1,
                title: "Pengingat Hutang",
                body: "Bayar cicilan kamu hari ini!",
              );
            },
            icon: const Icon(Icons.notifications),
          ),

          // 📄 EXPORT PDF
          IconButton(
            onPressed: () async {
              final file = await PdfService.generateDebtReport(debts);

              await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
            },
            icon: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),

      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _glow(220, colors.tertiary.withOpacity(0.18)),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _glow(260, colors.secondary.withOpacity(0.12)),
          ),
          Column(
            children: [
              FadeTransition(
                opacity: _summaryFade,
                child: SlideTransition(
                  position: _summarySlide,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Hutang",
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rupiah.format(totalAllDebt),
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Sudah Dibayar: ${rupiah.format(totalAllPaid)}",
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sisa: ${rupiah.format(totalAllRemaining)}",
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _insightFade,
                child: SlideTransition(
                  position: _insightSlide,
                  child: DebtInsightsCarousel(
                    debts: debts,
                    monthlyIncome: profileState.monthlyIncome,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: activeDebts.isEmpty
                      ? _buildEmptyState(textTheme, colors)
                      : ListView.builder(
                          key: const ValueKey('debts-list'),
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: activeDebts.length,
                          itemBuilder: (context, index) {
                            return DebtCard(debt: activeDebts[index]);
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),

      // ➕ TAMBAH
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDebtScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Tambah"),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme, ColorScheme colors) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffe5e7eb)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_rounded, color: colors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              "Belum ada data",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Mulai tambah cicilan agar ringkasanmu terisi.",
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xff6b7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}
