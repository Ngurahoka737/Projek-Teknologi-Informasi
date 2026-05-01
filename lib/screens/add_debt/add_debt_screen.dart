import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../core/formatters/thousands_separator_input_formatter.dart';
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

  final _monthsController = TextEditingController();
  final _monthlyAmountController = TextEditingController();
  final List<TextEditingController> _scheduleControllers = [];

  final amountFormat = NumberFormat.decimalPattern('id_ID');

  int _dueDay = 1;
  bool _isFixedSchedule = true;

  bool _isLoading = false;

  bool get isEdit => widget.debt != null;

  @override
  void initState() {
    super.initState();

    _monthsController.addListener(_handleMonthsChanged);

    if (isEdit) {
      _titleController.text = widget.debt!.title;

      _monthsController.text = widget.debt!.months.toString();
      if (widget.debt!.monthlySchedule != null &&
          widget.debt!.monthlySchedule!.isNotEmpty) {
        _isFixedSchedule = false;
        _ensureScheduleControllers(widget.debt!.months);
        final schedule = widget.debt!.monthlySchedule!;
        for (var i = 0; i < _scheduleControllers.length; i++) {
          final amount = i < schedule.length
              ? schedule[i]
              : widget.debt!.monthlyAverage;
          _scheduleControllers[i].text = amountFormat.format(amount.round());
        }
        _monthlyAmountController.text = amountFormat.format(
          widget.debt!.monthlyAverage.round(),
        );
      } else {
        _isFixedSchedule = true;
        _monthlyAmountController.text = amountFormat.format(
          widget.debt!.monthlyAmount.round(),
        );
      }
      _dueDay = widget.debt!.dueDay;
    }
  }

  void _handleMonthsChanged() {
    if (_isFixedSchedule) return;
    final months = int.tryParse(_monthsController.text) ?? 0;
    if (months <= 0) return;
    setState(() {
      _ensureScheduleControllers(months);
    });
  }

  void _ensureScheduleControllers(int count) {
    while (_scheduleControllers.length < count) {
      _scheduleControllers.add(TextEditingController());
    }
    while (_scheduleControllers.length > count) {
      _scheduleControllers.removeLast().dispose();
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

  DateTime _nextDueDate(int dueDay) {
    final now = DateTime.now();
    final safeDay = dueDay.clamp(1, 28).toInt();
    final candidate = DateTime(now.year, now.month, safeDay);
    if (candidate.isAfter(now) || candidate.isAtSameMomentAs(now)) {
      return candidate;
    }
    final nextMonth = DateTime(now.year, now.month + 1, safeDay);
    return nextMonth;
  }

  // ======================
  // SUBMIT
  // ======================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final months = int.tryParse(_monthsController.text) ?? 0;
      List<double>? schedule;
      var monthlyAmount = parseFormattedNumber(_monthlyAmountController.text);
      if (!_isFixedSchedule) {
        schedule = _scheduleControllers
            .map((controller) => parseFormattedNumber(controller.text))
            .toList();
        if (schedule.isNotEmpty) {
          final total = schedule.fold(0.0, (sum, item) => sum + item);
          monthlyAmount = total / schedule.length;
        }
      }
      final dueDate = _nextDueDate(_dueDay);
      final totalAmount = schedule != null && schedule.isNotEmpty
          ? schedule.fold(0.0, (sum, item) => sum + item)
          : months * monthlyAmount;

      // ======================
      // VALIDASI EDIT
      // ======================
      if (isEdit && totalAmount < widget.debt!.totalPaid) {
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
              months: months,
              monthlyAmount: monthlyAmount,
              monthlySchedule: schedule,
              dueDay: _dueDay,
              dueDate: dueDate,
            );
      } else {
        await ref
            .read(debtNotifierProvider.notifier)
            .addDebt(
              title: title,
              months: months,
              monthlyAmount: monthlyAmount,
              monthlySchedule: schedule,
              dueDay: _dueDay,
              dueDate: dueDate,
            );

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
    _monthsController.removeListener(_handleMonthsChanged);
    _titleController.dispose();
    _monthsController.dispose();
    _monthlyAmountController.dispose();
    for (final controller in _scheduleControllers) {
      controller.dispose();
    }
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
                      // TENOR (BULAN)
                      // ==================
                      TextFormField(
                        controller: _monthsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: "Tenor (bulan)",
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Tenor wajib diisi";
                          }

                          final months = int.tryParse(value) ?? 0;

                          if (months <= 0) {
                            return "Tenor minimal 1 bulan";
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ==================
                      // JENIS CICILAN
                      // ==================
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text("Sama tiap bulan"),
                            selected: _isFixedSchedule,
                            onSelected: (value) {
                              if (!value) return;
                              setState(() {
                                _isFixedSchedule = true;
                              });
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text("Berbeda"),
                            selected: !_isFixedSchedule,
                            onSelected: (value) {
                              if (!value) return;
                              final months =
                                  int.tryParse(_monthsController.text) ?? 0;
                              setState(() {
                                _isFixedSchedule = false;
                                if (months > 0) {
                                  _ensureScheduleControllers(months);
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_isFixedSchedule)
                        TextFormField(
                          controller: _monthlyAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsSeparatorInputFormatter()],
                          decoration: const InputDecoration(
                            labelText: "Cicilan per bulan",
                            prefixIcon: Icon(Icons.payments),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Nominal cicilan wajib diisi";
                            }

                            final amount = parseFormattedNumber(value);

                            if (amount <= 0) {
                              return "Nominal harus lebih dari 0";
                            }

                            return null;
                          },
                        )
                      else
                        Column(
                          children: List.generate(
                            _scheduleControllers.length,
                            (index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _scheduleControllers.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: TextFormField(
                                controller: _scheduleControllers[index],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  ThousandsSeparatorInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  labelText: "Cicilan bulan ${index + 1}",
                                  prefixIcon: const Icon(Icons.payments),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Nominal cicilan wajib diisi";
                                  }

                                  final amount = parseFormattedNumber(value);

                                  if (amount <= 0) {
                                    return "Nominal harus lebih dari 0";
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ==================
                      // JATUH TEMPO TANGGAL
                      // ==================
                      DropdownButtonFormField<int>(
                        value: _dueDay,
                        decoration: const InputDecoration(
                          labelText: "Jatuh tempo tiap tanggal",
                          prefixIcon: Icon(Icons.event),
                        ),
                        items: List.generate(28, (index) {
                          final day = index + 1;
                          return DropdownMenuItem(
                            value: day,
                            child: Text('Tanggal $day'),
                          );
                        }),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _dueDay = value;
                          });
                        },
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
