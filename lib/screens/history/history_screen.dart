import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_notifier.dart';
import '../../data/models/debt_model.dart';
import '../detail/debt_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final provider = ref.watch(debtNotifierProvider);
    final paidOffDebts = provider.where((d) => d.remaining <= 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Lunas"), centerTitle: true),

      body: paidOffDebts.isEmpty
          ? _buildEmpty(textTheme, colors)
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: paidOffDebts.length,
              itemBuilder: (context, index) {
                return _paidCard(context, paidOffDebts[index]);
              },
            ),
    );
  }

  Widget _buildEmpty(TextTheme textTheme, ColorScheme colors) {
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
              child: Icon(Icons.check_circle, color: colors.primary),
            ),
            const SizedBox(height: 12),
            Text(
              "Belum ada hutang lunas",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Selesaikan cicilan untuk melihat riwayat di sini.",
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

  Widget _paidCard(BuildContext context, DebtModel debt) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt)),
        );
      },

      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      debt.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff0f766e),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "LUNAS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              LinearProgressIndicator(
                value: 1,
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xff0f766e),
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Dibayar"),
                  Text(
                    format.format(debt.totalPaid),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
