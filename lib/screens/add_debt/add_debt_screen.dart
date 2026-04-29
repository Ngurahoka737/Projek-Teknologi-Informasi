import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/debt_notifier.dart';
import '../../data/models/debt_model.dart';
import '../../data/services/notification_service.dart';

class AddDebtScreen extends ConsumerStatefulWidget {
  final DebtModel? debt;

  const AddDebtScreen({super.key, this.debt});

  @override
  ConsumerState<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends ConsumerState<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();

  final _amountController = TextEditingController();

  final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  DateTime? _selectedDate;

  bool _isLoading = false;

  bool get isEdit => widget.debt != null;

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      _titleController.text = widget.debt!.title;

      _amountController.text = widget.debt!.totalAmount.toStringAsFixed(0);

      _selectedDate = widget.debt!.dueDate;
    }
  }

  // ======================
  // PICK DATE
  // ======================
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ======================
  // NOTIFIKASI
  // ======================
  Future<void> _scheduleReminders(String title, DateTime dueDate) async {
    final now = DateTime.now();

    final h7 = dueDate.subtract(const Duration(days: 7));

    final h1 = dueDate.subtract(const Duration(days: 1));

    if (h7.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: "Pengingat Hutang",
        body: "7 hari lagi jatuh tempo $title",
        date: h7,
      );
    }

    if (h1.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
        title: "Pengingat Hutang",
        body: "Besok jatuh tempo $title",
        date: h1,
      );
    }

    if (dueDate.isAfter(now)) {
      await NotificationService.scheduleNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2,
        title: "Pengingat Hutang",
        body: "Hari ini jatuh tempo $title",
        date: dueDate,
      );
    }
  }

  // ======================
  // SUBMIT
  // ======================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tanggal jatuh tempo wajib dipilih")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();

      final amount = double.tryParse(_amountController.text) ?? 0;

      final dueDate = _selectedDate!;

      // ======================
      // VALIDASI EDIT
      // ======================
      if (isEdit && amount < widget.debt!.totalPaid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Total hutang tidak boleh kurang dari pembayaran yang sudah masuk",
            ),
          ),
        );

        setState(() {
          _isLoading = false;
        });

        return;
      }

      if (isEdit) {
        await ref
            .read(debtNotifierProvider.notifier)
            .updateDebt(
              id: widget.debt!.id!,
              title: title,
              totalAmount: amount,
              dueDate: dueDate,
            );
      } else {
        await ref
            .read(debtNotifierProvider.notifier)
            .addDebt(title: title, totalAmount: amount, dueDate: dueDate);

        await _scheduleReminders(title, dueDate);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? "Data berhasil diupdate" : "Cicilan berhasil ditambahkan",
          ),
        ),
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
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Hutang" : "Tambah Cicilan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? "Perbarui data hutang yang sudah ada."
                    : "Tambah data cicilan baru agar pembayaran lebih teratur.",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // ==================
                      // NAMA CICILAN
                      // ==================
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Nama Cicilan",
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Nama cicilan wajib diisi";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================
                      // TOTAL HUTANG
                      // ==================
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: "Total Hutang",
                          prefixIcon: Icon(Icons.payments),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Total hutang wajib diisi";
                          }

                          final amount = double.tryParse(value);

                          if (amount == null) {
                            return "Masukkan angka valid";
                          }

                          if (amount <= 0) {
                            return "Nominal harus lebih dari 0";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================
                      // DATE PICKER
                      // ==================
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
                                child: Text(
                                  _selectedDate == null
                                      ? "Pilih Tanggal Jatuh Tempo"
                                      : dateFormat.format(_selectedDate!),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ==================
                      // BUTTON
                      // ==================
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(isEdit ? Icons.edit : Icons.save),
                          label: Text(
                            _isLoading
                                ? "Menyimpan..."
                                : isEdit
                                ? "Update Data"
                                : "Simpan Data",
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
}
