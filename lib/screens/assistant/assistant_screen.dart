import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters/thousands_separator_input_formatter.dart';
import '../../data/models/debt_model.dart';
import '../../data/services/ai_assistant_service.dart';
import '../../providers/debt_notifier.dart';
import '../../providers/profile_provider.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _chatController = TextEditingController();
  final _extraBudgetController = TextEditingController();
  final _scrollController = ScrollController();
  final _service = AiAssistantService();

  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isSending = false;
  bool _isPlanning = false;
  String? _planResult;
  String _strategy = 'snowball';

  final List<_ChatItem> _messages = [];

  @override
  void dispose() {
    _chatController.dispose();
    _extraBudgetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendChat() async {
    final input = _chatController.text.trim();
    if (input.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatItem(role: 'user', content: input));
      _isSending = true;
    });
    _chatController.clear();

    try {
      final context = _buildContext();
      final reply = await _service.sendChat(
        messages: _messages
            .map((item) => {'role': item.role, 'content': item.content})
            .toList(),
        context: context,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatItem(
            role: 'assistant',
            content: reply.trim().isEmpty
                ? 'Maaf, saya belum bisa menjawabnya sekarang.'
                : reply.trim(),
          ),
        );
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
      });
      _showError('Gagal menghubungi AI: $e');
    }
  }

  Future<void> _generatePlan() async {
    if (_isPlanning) return;

    final debts = _activeDebts();
    if (debts.isEmpty) {
      _showError('Tidak ada hutang aktif untuk dibuatkan rencana.');
      return;
    }

    setState(() {
      _isPlanning = true;
    });

    try {
      final context = _buildContext(
        extraBudget: parseFormattedNumber(_extraBudgetController.text),
        strategy: _strategy,
      );

      final reply = await _service.generatePlan(context: context);

      if (!mounted) return;
      setState(() {
        _planResult = reply.trim();
        _isPlanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPlanning = false;
      });
      _showError('Gagal membuat rencana: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, dynamic> _buildContext({double? extraBudget, String? strategy}) {
    final profile = ref.read(profileControllerProvider);
    final debts = _activeDebts();

    return {
      'currency': 'IDR',
      'monthlyIncome': profile.monthlyIncome ?? 0,
      'extraBudget': extraBudget ?? 0,
      'strategy': strategy,
      'debts': debts
          .map(
            (item) => {
              'title': item.title,
              'remaining': item.remaining,
              'monthly': item.monthlyAverage,
              'months': item.months,
              'totalPaid': item.totalPaid,
            },
          )
          .toList(),
    };
  }

  List<DebtModel> _activeDebts() {
    final debts = ref.read(debtNotifierProvider);
    return debts.where((item) => item.remaining > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final debts = _activeDebts();
    final income = ref.watch(profileControllerProvider).monthlyIncome ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Assistant'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Rencana Bayar'),
              Tab(text: 'Chat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildPlanTab(debts, income), _buildChatTab()],
        ),
      ),
    );
  }

  Widget _buildPlanTab(List<DebtModel> debts, double income) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buat rencana bayar berdasarkan data hutang aktif.',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _infoChip(
                          'Hutang aktif',
                          debts.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _infoChip(
                          'Penghasilan',
                          income <= 0 ? '-' : _rupiah.format(income),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _strategy,
                    decoration: const InputDecoration(
                      labelText: 'Strategi',
                      prefixIcon: Icon(Icons.timeline),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'snowball',
                        child: Text('Snowball (dari terkecil)'),
                      ),
                      DropdownMenuItem(
                        value: 'avalanche',
                        child: Text('Avalanche (bunga tertinggi)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _strategy = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _extraBudgetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Budget tambahan per bulan (opsional)',
                      prefixIcon: Icon(Icons.add_circle_outline),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPlanning ? null : _generatePlan,
                      icon: _isPlanning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isPlanning ? 'Menyusun...' : 'Buat Rencana'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_planResult != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: SelectableText(
                  _planResult!,
                  style: const TextStyle(height: 1.4),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xffe5e7eb)),
              ),
              child: const Text(
                'Tekan “Buat Rencana” untuk mendapatkan strategi bayar.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _emptyChat()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final item = _messages[index];
                    final isUser = item.role == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xff0f766e)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isUser
                              ? null
                              : Border.all(color: const Color(0xffe5e7eb)),
                        ),
                        child: Text(
                          item.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_isSending)
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'AI sedang mengetik...',
              style: TextStyle(fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Tanya soal rencana hutang atau budgeting...',
                  ),
                  onSubmitted: (_) => _sendChat(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _sendChat,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.smart_toy, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'Mulai chat dengan AI assistant Neistat.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff1f5f9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ChatItem {
  _ChatItem({required this.role, required this.content});

  final String role;
  final String content;
}
