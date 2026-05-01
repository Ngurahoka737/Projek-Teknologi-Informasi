import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_notifier.dart';
import '../../data/models/debt_model.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  final int debtId;

  const AddPaymentScreen({super.key, required this.debtId});

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final monthFormat = DateFormat('MMM yyyy', 'id_ID');

  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final Set<String> _selectedMonthKeys = {};
  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = ref.read(debtNotifierProvider);
      final debt = provider.firstWhere((item) => item.id == widget.debtId);
      final schedule = _buildSchedule(debt);
      final paidKeys = _paidMonthKeys(debt);
      final selectedMonths = schedule
          .where(
            (item) =>
                _selectedMonthKeys.contains(item.key) &&
                !paidKeys.contains(item.key),
          )
          .toList();

      if (selectedMonths.isEmpty) {
        throw Exception("Pilih minimal 1 bulan untuk dibayar");
      }

      final totalToPay = selectedMonths.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );
      if (totalToPay > debt.remaining) {
        throw Exception("Nominal melebihi sisa hutang");
      }

      for (final item in selectedMonths) {
        await ref
            .read(debtNotifierProvider.notifier)
            .addPayment(
              debtId: widget.debtId,
              amount: item.amount,
              date: item.date,
            );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran berhasil ditambahkan")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(debtNotifierProvider);
    final DebtModel debt = provider.firstWhere(
      (item) => item.id == widget.debtId,
    );
    final schedule = _buildSchedule(debt);
    final paidKeys = _paidMonthKeys(debt);
    final unpaidMonths = schedule
        .where((item) => !paidKeys.contains(item.key))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Pembayaran")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tambahkan pembayaran agar progress hutang selalu terupdate.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            // =====================
            // INFO CARD
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
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoRow("Total Hutang", rupiah.format(debt.totalAmount)),
                  _infoRow("Sudah Dibayar", rupiah.format(debt.totalPaid)),
                  _infoRow("Sisa Hutang", rupiah.format(debt.remaining)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // =====================
            // BULAN TAGIHAN
            // =====================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pilih bulan yang dibayar",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: unpaidMonths.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _selectedMonthKeys
                                      ..clear()
                                      ..addAll(
                                        unpaidMonths.map((item) => item.key),
                                      );
                                  });
                                },
                          child: const Text("Centang semua"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (schedule.isEmpty)
                      const Text(
                        "Belum ada jadwal cicilan.",
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Column(
                        children: schedule.map((item) {
                          final isPaid = paidKeys.contains(item.key);
                          final isSelected = _selectedMonthKeys.contains(
                            item.key,
                          );
                          return CheckboxListTile(
                            value: isPaid || isSelected,
                            onChanged: isPaid
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedMonthKeys.add(item.key);
                                      } else {
                                        _selectedMonthKeys.remove(item.key);
                                      }
                                    });
                                  },
                            title: Text(monthFormat.format(item.date)),
                            subtitle: Text(rupiah.format(item.amount)),
                            secondary: Icon(
                              isPaid ? Icons.check_circle : Icons.schedule,
                              color: isPaid ? Colors.green : Colors.orange,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isLoading ? "Menyimpan..." : "Simpan Pembayaran",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white70)),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<_MonthItem> _buildSchedule(DebtModel debt) {
    if (debt.months <= 0) return [];
    final safeDay = debt.dueDay.clamp(1, 28).toInt();
    final baseDate = DateTime(debt.dueDate.year, debt.dueDate.month, safeDay);

    return List.generate(debt.months, (index) {
      final date = DateTime(baseDate.year, baseDate.month + index, safeDay);
      return _MonthItem(
        date: date,
        key: _monthKey(date),
        amount: debt.amountForIndex(index),
      );
    });
  }

  Set<String> _paidMonthKeys(DebtModel debt) {
    return debt.payments.map((payment) => _monthKey(payment.date)).toSet();
  }

  String _monthKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }
}

class _MonthItem {
  _MonthItem({required this.date, required this.key, required this.amount});

  final DateTime date;
  final String key;
  final double amount;
}
