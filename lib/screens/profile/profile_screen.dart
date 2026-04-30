import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/formatters/thousands_separator_input_formatter.dart';
import '../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController();
  final _amountFormat = NumberFormat.decimalPattern('id_ID');
  String? _seededUserId;
  String? _lastUserId;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    final value = parseFormattedNumber(_incomeController.text);
    await ref
        .read(profileControllerProvider.notifier)
        .updateMonthlyIncome(value);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Penghasilan tersimpan.')));
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (_lastUserId != currentUid) {
      _lastUserId = currentUid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(profileControllerProvider.notifier).reloadForUser(currentUid);
      });
    }

    if (!profileState.isLoading && _seededUserId != profileState.userId) {
      _seededUserId = profileState.userId;
      _incomeController.text = profileState.monthlyIncome == null
          ? ''
          : _amountFormat.format(profileState.monthlyIncome!.round());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Atur penghasilan bulanan untuk menghitung rasio hutang.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _incomeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsSeparatorInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Penghasilan per bulan',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Penghasilan wajib diisi';
                          }

                          final number = parseFormattedNumber(value);
                          if (number <= 0) {
                            return 'Penghasilan harus lebih dari 0';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: profileState.isLoading
                              ? null
                              : _saveIncome,
                          icon: profileState.isLoading
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
                            profileState.isLoading ? 'Menyimpan...' : 'Simpan',
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
