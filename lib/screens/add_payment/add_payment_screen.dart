import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_provider.dart';
import '../../data/models/debt_model.dart';

class AddPaymentScreen extends StatefulWidget {
  final int debtId;

  const AddPaymentScreen({super.key, required this.debtId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  final rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<DebtProvider>(context, listen: false);

      final debt = provider.debts.firstWhere(
        (item) => item.id == widget.debtId,
      );

      final amount = double.tryParse(_amountController.text) ?? 0;

      if (amount <= 0) {
        throw Exception("Nominal harus lebih dari 0");
      }

      if (amount > debt.remaining) {
        throw Exception("Nominal melebihi sisa hutang");
      }

      await provider.addPayment(
        debtId: widget.debtId,
        amount: amount,
        date: _selectedDate,
      );

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
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DebtProvider>(context);

    final DebtModel debt = provider.debts.firstWhere(
      (item) => item.id == widget.debtId,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Pembayaran")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Form(
          key: _formKey,

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
              // FORM
              // =====================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Nominal Pembayaran",
                          prefixIcon: Icon(Icons.payments),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Nominal wajib diisi";
                          }

                          final number = double.tryParse(value);

                          if (number == null) {
                            return "Masukkan angka valid";
                          }

                          if (number <= 0) {
                            return "Nominal harus lebih dari 0";
                          }

                          if (number > debt.remaining) {
                            return "Melebihi sisa hutang";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(dateFormat.format(_selectedDate)),
                              ),

                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

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
}
