import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/debt_model.dart';
import '../screens/add_payment/add_payment_screen.dart';
import '../screens/detail/debt_detail_screen.dart';

class DebtCard extends StatelessWidget {
  final DebtModel debt;

  const DebtCard({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    final bool isPaidOff = debt.remaining <= 0;

    final rupiah = NumberFormat.currency(
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 TITLE
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
                      color: isPaidOff
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPaidOff ? "LUNAS" : "AKTIF",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPaidOff ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              //PROGRESS BAR
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: debt.progress,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 10),

              //INFO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Sisa", style: TextStyle(color: Colors.grey.shade600)),
                  Text(
                    "${(debt.progress * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                rupiah.format(debt.remaining),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              //BUTTON
              if (!isPaidOff)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddPaymentScreen(debtId: debt.id!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.payments),
                    label: const Text("Bayar Sekarang"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
