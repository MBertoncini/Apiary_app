import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/statistiche_service.dart';
import '../../../services/ai_quota_local_tracker.dart';
import '../../../services/ai_quota_service.dart';
import '../../../services/language_service.dart';
import '../../../l10n/app_strings.dart';
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

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  List<String> get _suggerimenti => [
    _s.nlQuerySuggerimento1,
    _s.nlQuerySuggerimento2,
    _s.nlQuerySuggerimento3,
    _s.nlQuerySuggerimento4,
    _s.nlQuerySuggerimento5,
    _s.nlQuerySuggerimento6,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_service == null) {
      final quotaService = Provider.of<AiQuotaService>(context, listen: false);
      _service = context.read<StatisticheService>();
      _tracker.getGroqApiKey().then((key) {
        if (mounted) {
          setState(() => _groqKey = key);
          quotaService.setHasPersonalGroqKey(key.isNotEmpty);
        }
      });
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

    // Rileggi la chiave Groq persistita: può essere stata modificata dalle
    // impostazioni dopo che questo tab è stato costruito. Senza questa
    // rilettura il backend non saprebbe della chiave appena salvata e
    // continuerebbe a usare il pool di sistema.
    try {
      final freshKey = await _tracker.getGroqApiKey();
      if (freshKey != _groqKey && mounted) {
        setState(() => _groqKey = freshKey);
        Provider.of<AiQuotaService>(context, listen: false)
            .setHasPersonalGroqKey(freshKey.isNotEmpty);
      }
    } catch (_) {
      // Non bloccare la chiamata se la lettura dalla cache fallisce.
    }

    try {
      final result = await _service!.chiediAI(domanda, groqApiKey: _groqKey.isNotEmpty ? _groqKey : null);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      final raw = e.toString();
      final s = _s;
      String msg;
      if (raw.contains('504') || raw.contains('timeout') || raw.contains('lento')) {
        msg = s.nlQueryErrLento;
      } else if (raw.contains('400') || raw.contains('sicura') || raw.contains('non posso')) {
        msg = s.nlQueryErrRifiuto;
      } else if (raw.contains('401') || raw.contains('403')) {
        // Sessione scaduta o permessi insufficienti.
        msg = s.nlQueryErrSessione;
      } else if (raw.contains('500') || raw.contains('502') || raw.contains('503')) {
        msg = s.nlQueryErrServizio;
      } else {
        msg = s.nlQueryErrGenerico;
      }
      // In debug mode mostra anche il dettaglio raw per accelerare il triage.
      if (kDebugMode) {
        msg = '$msg\n[debug] $raw';
      }
      setState(() { _error = msg; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Provider.of<LanguageService>(context);
    final s = _s;
    // Reattività alla quota: ricostruisce quando il gate stats cambia.
    final quotaService = context.watch<AiQuotaService>();
    final statsBlocked = !quotaService.canCall(AiFeature.stats);
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            children: [
              // Domande suggerite
              Text(s.nlQuerySuggerite, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
                      Text(s.nlQueryPensando, style: const TextStyle(color: Colors.grey)),
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
                          Text(s.nlQueryRispostaAI, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD4A017))),
                          const Spacer(),
                          if (_result!['totale_righe'] != null)
                            Text(s.nlQueryRisultati(_result!['totale_righe'] as int), style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

        // Input field fisso in basso (con banner quota se bloccata)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (statsBlocked)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: Colors.orange.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.quotaStatsExhausted,
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !statsBlocked,
                      decoration: InputDecoration(
                        hintText: statsBlocked ? s.nlQueryInputHintExhausted : s.nlQueryInputHint,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: statsBlocked ? null : _chiedi,
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    onPressed: (_loading || statsBlocked) ? null : () => _chiedi(_controller.text),
                    backgroundColor: statsBlocked ? Colors.grey.shade400 : const Color(0xFFD4A017),
                    child: _loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(statsBlocked ? Icons.block : Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
