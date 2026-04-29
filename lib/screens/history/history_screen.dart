import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_provider.dart';
import '../../data/models/debt_model.dart';
import '../detail/debt_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DebtProvider>(context);

    final paidOffDebts = provider.debts.where((d) => d.remaining <= 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Lunas"), centerTitle: true),

      body: paidOffDebts.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: paidOffDebts.length,
              itemBuilder: (context, index) {
                return _paidCard(context, paidOffDebts[index]);
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle, size: 70, color: Colors.green),
          SizedBox(height: 14),
          Text(
            "Belum ada hutang lunas",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
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
                      color: Colors.green,
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
                color: Colors.green,
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
