// lib/screens/voice_entry_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/voice_entry.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/voice_queue_service.dart';
import '../constants/theme_constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../services/regina_service.dart';

class VoiceEntryVerificationScreen extends StatefulWidget {
  final VoiceEntryBatch batch;
  final Function onSuccess;
  final Function onCancel;
  
  const VoiceEntryVerificationScreen({
    Key? key,
    required this.batch,
    required this.onSuccess,
    required this.onCancel,
  }) : super(key: key);
  
  @override
  _VoiceEntryVerificationScreenState createState() => _VoiceEntryVerificationScreenState();
}

class _VoiceEntryVerificationScreenState extends State<VoiceEntryVerificationScreen> {
  bool _isSubmitting = false;
  String? _error;
  int _currentIndex = 0;
  List<VoiceEntry> _editedEntries = [];
  // Controllers keyed by field name, rebuilt only when the entry index changes.
  final Map<String, TextEditingController> _controllers = {};
  final VoiceQueueService _queueService = VoiceQueueService();

  @override
  void initState() {
    super.initState();
    _editedEntries = List.from(widget.batch.entries);
    _rebuildControllers();
    // Persist immediately – Gemini tokens are already spent; do not lose this data.
    _queueService.saveVerificationDraft(_editedEntries);
  }

  void _rebuildControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    if (_editedEntries.isEmpty) return;
    final e = _editedEntries[_currentIndex];
    _controllers['apiarioNome'] = TextEditingController(text: e.apiarioNome ?? '');
    _controllers['arniaNumero'] = TextEditingController(text: e.arniaNumero?.toString() ?? '');
    _controllers['numeroCelleReali'] = TextEditingController(text: e.numeroCelleReali?.toString() ?? '');
    _controllers['telainiCovata'] = TextEditingController(text: e.telainiCovata?.toString() ?? '');
    _controllers['telainiScorte'] = TextEditingController(text: e.telainiScorte?.toString() ?? '');
    _controllers['telainiDiaframma'] = TextEditingController(text: e.telainiDiaframma?.toString() ?? '');
    _controllers['tealiniFoglioCereo'] = TextEditingController(text: e.tealiniFoglioCereo?.toString() ?? '');
    _controllers['telainiNutritore'] = TextEditingController(text: e.telainiNutritore?.toString() ?? '');
    _controllers['tipoProblema'] = TextEditingController(text: e.tipoProblema ?? '');
    _controllers['note'] = TextEditingController(text: e.note ?? '');
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  
  void _nextEntry() {
    if (_currentIndex < _editedEntries.length - 1) {
      setState(() {
        _currentIndex++;
        _rebuildControllers();
      });
    }
  }

  void _previousEntry() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _rebuildControllers();
      });
    }
  }

  void _removeEntry() {
    setState(() {
      _editedEntries.removeAt(_currentIndex);
      if (_currentIndex >= _editedEntries.length) {
        _currentIndex = _editedEntries.length - 1;
      }
      if (_currentIndex < 0) _currentIndex = 0;
      _rebuildControllers();
    });
    // Keep draft in sync so a removed entry is not restored on crash recovery.
    _queueService.saveVerificationDraft(_editedEntries);
  }
  
  Future<void> _saveAll() async {
    if (_editedEntries.isEmpty) {
      await _queueService.clearVerificationDraft();
      widget.onCancel();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    // Build arniaNumero → DB pk lookup from local cache.
    final cachedArnie = await storageService.getStoredData('arnie');
    final Map<String, int> arnieLookup = {};
    for (final raw in cachedArnie) {
      final key = '${raw['apiario']}_${raw['numero']}';
      if (raw['id'] != null) arnieLookup[key] = raw['id'] as int;
    }

    int? resolveArniaId(VoiceEntry entry) {
      if (entry.arniaId != null) return entry.arniaId;
      if (entry.arniaNumero == null) return null;
      if (entry.apiarioId != null) {
        final key = '${entry.apiarioId}_${entry.arniaNumero}';
        if (arnieLookup.containsKey(key)) return arnieLookup[key];
      }
      // Fallback: match by numero alone (single-apiario case).
      for (final raw in cachedArnie) {
        if (raw['numero'] == entry.arniaNumero) return raw['id'] as int?;
      }
      return null;
    }

    // Per-entry save: never abort on a single failure.
    final List<VoiceEntry> remaining = [];
    final List<String> errors = [];
    int savedCount = 0;

    for (final entry in _editedEntries) {
      if (!entry.isValid()) {
        // Keep invalid entries in the list so the user can fix them.
        remaining.add(entry);
        errors.add('Arnia ${entry.arniaNumero ?? '?'}: dati non validi, saltata.');
        continue;
      }

      final arniaId = resolveArniaId(entry);
      if (arniaId == null) {
        remaining.add(entry);
        errors.add(
            'Arnia ${entry.arniaNumero ?? '?'}: non trovata in cache. '
            'Aggiorna la lista arnie e riprova.');
        continue;
      }

      try {
        final controlloData = entry.toControlloData();
        controlloData.remove('arnia_id');
        controlloData['arnia'] = arniaId;
        await apiService.post('controlli/', controlloData);
        savedCount++;

        // Auto-crea scheda regina base se segnalata per la prima volta
        if (entry.presenzaRegina == true) {
          await ReginaService.maybeAutoCreate(
            arniaId: arniaId,
            presenzaRegina: true,
            dataControllo: DateFormat('yyyy-MM-dd').format(
              entry.data ?? DateTime.now(),
            ),
            apiService: apiService,
            storageService: storageService,
          );
        }

        // Se la regina è stata colorata, aggiorna il colore nel database
        if (entry.reginaColorata == true && entry.coloreRegina != null) {
          try {
            final reginaData = await apiService.get('arnie/$arniaId/regina/');
            if (reginaData != null && reginaData['id'] != null) {
              await apiService.patch(
                'regine/${reginaData['id']}/',
                {'colore_marcatura': entry.coloreRegina, 'marcata': true},
              );
            }
          } catch (e) {
            debugPrint('Errore aggiornamento colore regina arnia $arniaId: $e');
          }
        }
      } catch (e) {
        remaining.add(entry);
        errors.add('Arnia ${entry.arniaNumero ?? '?'}: ${e.toString()}');
      }
    }

    // Update the list and draft to only the entries that still need saving.
    _editedEntries = remaining;
    if (remaining.isEmpty) {
      await _queueService.clearVerificationDraft();
    } else {
      await _queueService.saveVerificationDraft(remaining);
    }

    // Clamp index after potential list shrink.
    if (_currentIndex >= _editedEntries.length) {
      _currentIndex = _editedEntries.isEmpty ? 0 : _editedEntries.length - 1;
    }
    _rebuildControllers();

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (remaining.isEmpty) {
      // All saved.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dati salvati con successo ($savedCount record)'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onSuccess([]);
    } else if (savedCount > 0) {
      // Partial success – show which ones failed and stay on screen.
      final summary = errors.join('\n');
      setState(() {
        _error = 'Salvati $savedCount record. '
            '${remaining.length} non salvati:\n$summary';
      });
    } else {
      // All failed.
      final summary = errors.join('\n');
      setState(() {
        _error = 'Nessun record salvato:\n$summary';
      });
    }
  }
  
  void _updateEntry(VoiceEntry updatedEntry) {
    setState(() {
      _editedEntries[_currentIndex] = updatedEntry;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verifica dati vocali'),
        actions: [
          if (_editedEntries.isNotEmpty) IconButton(
            icon: Icon(Icons.delete),
            onPressed: _removeEntry,
            tooltip: 'Rimuovi registrazione',
          ),
        ],
      ),
      body: _isSubmitting
          ? LoadingWidget(message: 'Salvataggio in corso...')
          : _error != null
              ? CustomErrorWidget(
                  errorMessage: _error!,
                  onRetry: _saveAll,
                )
              : _editedEntries.isEmpty
                  ? _buildEmptyState()
                  : _buildEntryVerificationForm(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun dato da verificare',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Torna indietro e registra nuove ispezioni',
            style: TextStyle(
              color: ThemeConstants.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => widget.onCancel(),
            child: Text('Torna indietro'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEntryVerificationForm() {
    final entry = _editedEntries[_currentIndex];
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Navigation indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Record ${_currentIndex + 1} di ${_editedEntries.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeConstants.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Location section
          _buildSectionTitle('Posizione'),
          _buildTextField(
            label: 'Apiario',
            controllerKey: 'apiarioNome',
            onChanged: (value) {
              _updateEntry(entry.copyWith(apiarioNome: value));
            },
          ),
          _buildTextField(
            label: 'Arnia',
            controllerKey: 'arniaNumero',
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateEntry(entry.copyWith(
                arniaNumero: int.tryParse(value),
              ));
            },
          ),
          const SizedBox(height: 16),
          
          // Date and type section
          _buildSectionTitle('Informazioni generali'),
          _buildDatePicker(
            label: 'Data',
            value: entry.data ?? DateTime.now(),
            onChanged: (date) {
              _updateEntry(entry.copyWith(data: date));
            },
          ),
          _buildDropdownField(
            label: 'Tipo',
            value: entry.tipoComando,
            items: ['ispezione', 'controllo', 'regina', 'telaini', 'trattamento'],
            onChanged: (value) {
              _updateEntry(entry.copyWith(tipoComando: value));
            },
          ),
          const SizedBox(height: 16),
          
          // Queen section
          _buildSectionTitle('Regina'),
          // Stato regina a 3 stati
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                _buildStatoReginaChip(entry, 'assente', 'Assente', Colors.red.shade300),
                SizedBox(width: 6),
                _buildStatoReginaChip(entry, 'presente', 'Presente', Colors.orange),
                SizedBox(width: 6),
                _buildStatoReginaChip(entry, 'vista', 'Vista', Colors.amber.shade700),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildSwitchField(
                  label: 'Uova fresche',
                  value: entry.uovaFresche ?? false,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(uovaFresche: value));
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSwitchField(
                  label: 'Celle reali',
                  value: entry.celleReali ?? false,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(celleReali: value));
                  },
                ),
              ),
            ],
          ),
          if (entry.celleReali == true)
            _buildTextField(
              label: 'Numero celle reali',
              controllerKey: 'numeroCelleReali',
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateEntry(entry.copyWith(
                  numeroCelleReali: int.tryParse(value),
                ));
              },
            ),
          const SizedBox(height: 16),
          
          // Frames section
          _buildSectionTitle('Telaini'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Covata',
                  controllerKey: 'telainiCovata',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(telainiCovata: int.tryParse(value)));
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  label: 'Scorte',
                  controllerKey: 'telainiScorte',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(telainiScorte: int.tryParse(value)));
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  label: 'Diaframma',
                  controllerKey: 'telainiDiaframma',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(telainiDiaframma: int.tryParse(value)));
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Foglio cereo',
                  controllerKey: 'tealiniFoglioCereo',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(tealiniFoglioCereo: int.tryParse(value)));
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  label: 'Nutritore',
                  controllerKey: 'telainiNutritore',
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(telainiNutritore: int.tryParse(value)));
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ThemeConstants.primaryColor.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Totale', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      SizedBox(height: 4),
                      Text(
                        '${entry.telainiTotali}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThemeConstants.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildDropdownField(
            label: 'Forza famiglia',
            value: entry.forzaFamiglia,
            items: ['debole', 'normale', 'forte'],
            onChanged: (value) {
              _updateEntry(entry.copyWith(forzaFamiglia: value));
            },
          ),
          const SizedBox(height: 16),
          
          // Problems section
          _buildSectionTitle('Problemi'),
          Row(
            children: [
              Expanded(
                child: _buildSwitchField(
                  label: 'Sciamatura',
                  value: entry.sciamatura ?? false,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(sciamatura: value));
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSwitchField(
                  label: 'Problemi sanitari',
                  value: entry.problemiSanitari ?? false,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(problemiSanitari: value));
                  },
                ),
              ),
            ],
          ),
          if (entry.problemiSanitari == true)
            _buildTextField(
              label: 'Tipo di problema',
              controllerKey: 'tipoProblema',
              onChanged: (value) {
                _updateEntry(entry.copyWith(tipoProblema: value));
              },
            ),
          const SizedBox(height: 16),

          // Queen coloring section
          _buildSectionTitle('Colorazione regina'),
          _buildSwitchField(
            label: 'Regina colorata/marcata',
            value: entry.reginaColorata ?? false,
            onChanged: (value) {
              _updateEntry(entry.copyWith(
                reginaColorata: value,
                coloreRegina: value ? entry.coloreRegina : null,
              ));
            },
          ),
          if (entry.reginaColorata == true) ...[
            const SizedBox(height: 8),
            _buildDropdownField<String>(
              label: 'Colore marcatura',
              value: entry.coloreRegina,
              items: ['bianco', 'giallo', 'rosso', 'verde', 'blu'],
              onChanged: (value) {
                _updateEntry(entry.copyWith(coloreRegina: value));
              },
            ),
          ],
          const SizedBox(height: 16),

          // Notes section
          _buildSectionTitle('Note'),
          _buildTextField(
            label: 'Note aggiuntive',
            controllerKey: 'note',
            maxLines: 3,
            onChanged: (value) {
              _updateEntry(entry.copyWith(note: value));
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    return BottomAppBar(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Navigation buttons
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _currentIndex > 0 ? _previousEntry : null,
                  tooltip: 'Precedente',
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _currentIndex < _editedEntries.length - 1 ? _nextEntry : null,
                  tooltip: 'Successivo',
                ),
              ],
            ),
            
            // Action buttons
            Row(
              children: [
                TextButton(
                  onPressed: () => widget.onCancel(),
                  child: Text('ANNULLA'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _saveAll,
                  child: Text('SALVA TUTTO'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: ThemeConstants.primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildStatoReginaChip(VoiceEntry entry, String stato, String label, Color color) {
    final presenzaRegina = entry.presenzaRegina ?? true;
    final reginaVista = entry.reginaVista ?? false;
    String currentStato = !presenzaRegina ? 'assente' : (reginaVista ? 'vista' : 'presente');
    final isSelected = currentStato == stato;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _updateEntry(entry.copyWith(
            presenzaRegina: stato != 'assente',
            reginaVista: stato == 'vista',
          ));
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.85) : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.4),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String controllerKey,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _controllers[controllerKey],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildSwitchField({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: ThemeConstants.primaryColor,
        ),
      ],
    );
  }
  
  Widget _buildDropdownField<T>({
    required String label,
    T? value,
    required List<T> items,
    required Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required Function(DateTime) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(Duration(days: 1)),
          );
          if (date != null) {
            onChanged(date);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('dd/MM/yyyy').format(value)),
              Icon(Icons.calendar_today, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}