import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/debt_model.dart';
import '../../providers/debt_notifier.dart';
import '../add_debt/add_debt_screen.dart';

class DebtDetailScreen extends ConsumerWidget {
  final DebtModel debt;

  const DebtDetailScreen({super.key, required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    final bool isPaidOff = debt.remaining <= 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Hutang"),

        //EDIT + HAPUS
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddDebtScreen(debt: debt)),
              );
            },
            icon: const Icon(Icons.edit),
          ),

          IconButton(
            onPressed: () {
              _deleteDialog(context, ref);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            // =====================
            // HEADER CARD
            // =====================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [Color(0xff4f46e5), Color(0xff6366f1)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.title,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: debt.progress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "${(debt.progress * 100).toStringAsFixed(0)}% selesai",
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaidOff ? "LUNAS" : "AKTIF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =====================
            // INFO
            // =====================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _item(
                      Icons.payments,
                      "Total Hutang",
                      rupiah.format(debt.totalAmount),
                    ),

                    const Divider(),

                    _item(
                      Icons.calendar_month,
                      "Tenor",
                      "${debt.months} bulan",
                    ),

                    const Divider(),

                    _item(
                      Icons.payments_outlined,
                      "Cicilan / bulan",
                      rupiah.format(debt.monthlyAmount),
                    ),

                    const Divider(),

                    _item(Icons.event, "Jatuh tempo", "Tanggal ${debt.dueDay}"),

                    const Divider(),

                    _item(
                      Icons.check_circle,
                      "Sudah Dibayar",
                      rupiah.format(debt.totalPaid),
                    ),

                    const Divider(),

                    _item(
                      Icons.account_balance_wallet,
                      "Sisa Hutang",
                      rupiah.format(debt.remaining),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Riwayat Pembayaran",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: debt.payments.isEmpty
                  ? const Center(child: Text("Belum ada pembayaran"))
                  : ListView.builder(
                      itemCount: debt.payments.length,
                      itemBuilder: (context, index) {
                        final payment = debt.payments[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.payment),
                            ),

                            title: Text(
                              rupiah.format(payment.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: Text(dateFormat.format(payment.date)),

                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deletePaymentDialog(
                                  context,
                                  ref,
                                  debt.id!,
                                  payment.id!,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // DIALOG HAPUS
  // =========================
  void _deleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Hutang?"),
        content: const Text("Data akan dihapus permanen."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(debtNotifierProvider.notifier)
                  .deleteDebt(debt.id!);

              if (!context.mounted) return;

              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _deletePaymentDialog(
    BuildContext context,
    WidgetRef ref,
    int debtId,
    int paymentId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Pembayaran?"),
        content: const Text("Riwayat pembayaran ini akan dihapus."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(debtNotifierProvider.notifier)
                  .deletePayment(debtId: debtId, paymentId: paymentId);

              if (!context.mounted) return;

              Navigator.pop(context);
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DebtDetailScreen(debt: debt)),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }
}
