import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/statistiche_service.dart';
import '../../../services/api_service.dart';
import '../../../services/ai_quota_local_tracker.dart';
import 'risultato_query_widget.dart';

class NLQueryTab extends StatefulWidget {
  const NLQueryTab({super.key});

  @override
  State<NLQueryTab> createState() => _NLQueryTabState();
}

class _NLQueryTabState extends State<NLQueryTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  StatisticheService? _service;
  final _tracker = AiQuotaLocalTracker();
  String _groqKey = '';
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  String? _domandaCorrente;

  static const _suggerimenti = [
    'Quali arnie non controllo da 30 giorni?',
    'Quando ho prodotto più miele?',
    'Quali regine hanno la valutazione più alta?',
    'Quanti controlli ho fatto quest\'anno?',
    'Qual è il mio bilancio di quest\'anno?',
    'Quali trattamenti ho fatto?',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_service == null) {
      _service = StatisticheService(Provider.of<ApiService>(context, listen: false));
      _tracker.getGroqApiKey().then((key) { if (mounted) setState(() => _groqKey = key); });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chiedi(String domanda) async {
    if (domanda.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _domandaCorrente = domanda;
    });
    _controller.clear();

    // Scroll verso il basso
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }

    try {
      final result = await _service!.chiediAI(domanda, groqApiKey: _groqKey.isNotEmpty ? _groqKey : null);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('504') || msg.contains('timeout') || msg.contains('lento')) {
        msg = 'Il server AI è lento, riprova tra poco';
      } else if (msg.contains('400') || msg.contains('sicura') || msg.contains('non posso')) {
        msg = 'Non posso rispondere a questa domanda';
      } else {
        msg = 'Errore: si prega di riprovare';
      }
      setState(() { _error = msg; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              // Domande suggerite
              const Text('Domande suggerite:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _suggerimenti.map((s) => ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  onPressed: () => _chiedi(s),
                  avatar: const Icon(Icons.lightbulb_outline, size: 14),
                )).toList(),
              ),
              const SizedBox(height: 20),

              // Domanda corrente
              if (_domandaCorrente != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A1A2E).withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Color(0xFFD4A017)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_domandaCorrente!, style: const TextStyle(fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Loading
              if (_loading)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('AI sta pensando…', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),

              // Errore
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),

              // Risultato
              if (_result != null && !_loading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4A017).withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.smart_toy, color: Color(0xFFD4A017), size: 20),
                          const SizedBox(width: 6),
                          const Text('Risposta AI', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                          const Spacer(),
                          if (_result!['totale_righe'] != null)
                            Text('${_result!['totale_righe']} risultati', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Divider(),
                      if (_result!['messaggio'] != null)
                        Text(_result!['messaggio'] as String, style: const TextStyle(color: Colors.grey))
                      else
                        RisultatoQueryWidget(result: _result!),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Input field fisso in basso
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Fai una domanda sui tuoi dati…',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: _chiedi,
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                onPressed: _loading ? null : () => _chiedi(_controller.text),
                backgroundColor: const Color(0xFFD4A017),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
