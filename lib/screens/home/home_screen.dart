import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_notifier.dart';
import '../../widgets/debt_card.dart';
import '../add_debt/add_debt_screen.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/pdf_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ref.read(debtNotifierProvider.notifier).loadDebts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtNotifierProvider);
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

      body: Column(
        children: [
          //SUMMARY CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xff4f46e5), Color(0xff6366f1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Hutang",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 6),

                Text(
                  rupiah.format(totalAllDebt),
                  style: const TextStyle(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  "Sudah Dibayar: ${rupiah.format(totalAllPaid)}",
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 6),

                Text(
                  "Sisa: ${rupiah.format(totalAllRemaining)}",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          //LIST
          Expanded(
            child: activeDebts.isEmpty
                ? const Center(child: Text("Belum ada data"))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: activeDebts.length,
                    itemBuilder: (context, index) {
                      return DebtCard(debt: activeDebts[index]);
                    },
                  ),
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
}
