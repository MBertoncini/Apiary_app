// lib/screens/voice_entry_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/voice_entry.dart';
import '../services/api_service.dart';
import '../constants/theme_constants.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

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
  
  @override
  void initState() {
    super.initState();
    // Create deep copy of entries for editing
    _editedEntries = List.from(widget.batch.entries);
  }
  
  void _nextEntry() {
    if (_currentIndex < _editedEntries.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }
  
  void _previousEntry() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
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
    });
  }
  
  Future<void> _saveAll() async {
    if (_editedEntries.isEmpty) {
      widget.onCancel();
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      List<Map<String, dynamic>> results = [];
      
      // Process each entry
      for (var entry in _editedEntries) {
        // Skip invalid entries
        if (!entry.isValid()) continue;
        
        // Determine the type of data to submit
        if (entry.tipoComando == 'controllo' || entry.tipoComando == 'ispezione') {
          // Create inspection
          final controlloData = entry.toControlloData();
          final response = await apiService.post('controlli/', controlloData);
          results.add(response);
        } else if (entry.tipoComando == 'trattamento') {
          // Create treatment
          // TODO: Implement treatment submission
        } else {
          // Default to creating an inspection
          final controlloData = entry.toControlloData();
          final response = await apiService.post('controlli/', controlloData);
          results.add(response);
        }
      }
      
      // All entries processed successfully
      setState(() {
        _isSubmitting = false;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dati salvati con successo (${results.length} record)'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Call success callback
      widget.onSuccess(results);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = e.toString();
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
          SizedBox(height: 16),
          Text(
            'Nessun dato da verificare',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Torna indietro e registra nuove ispezioni',
            style: TextStyle(
              color: ThemeConstants.textSecondaryColor,
            ),
          ),
          SizedBox(height: 24),
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
          SizedBox(height: 24),
          
          // Location section
          _buildSectionTitle('Posizione'),
          _buildTextField(
            label: 'Apiario',
            value: entry.apiarioNome,
            onChanged: (value) {
              _updateEntry(entry.copyWith(apiarioNome: value));
            },
          ),
          _buildTextField(
            label: 'Arnia',
            value: entry.arniaNumero?.toString(),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateEntry(entry.copyWith(
                arniaNumero: int.tryParse(value),
              ));
            },
          ),
          SizedBox(height: 16),
          
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
          SizedBox(height: 16),
          
          // Queen section
          _buildSectionTitle('Regina'),
          Row(
            children: [
              Expanded(
                child: _buildSwitchField(
                  label: 'Presente',
                  value: entry.presenzaRegina ?? false,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(presenzaRegina: value));
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSwitchField(
                  label: 'Vista',
                  value: entry.reginaVista ?? false,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(reginaVista: value));
                  },
                ),
              ),
            ],
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
              value: entry.numeroCelleReali?.toString(),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _updateEntry(entry.copyWith(
                  numeroCelleReali: int.tryParse(value),
                ));
              },
            ),
          SizedBox(height: 16),
          
          // Frames section
          _buildSectionTitle('Telaini'),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Totali',
                  value: entry.telainiTotali?.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(
                      telainiTotali: int.tryParse(value),
                    ));
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Covata',
                  value: entry.telainiCovata?.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(
                      telainiCovata: int.tryParse(value),
                    ));
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Scorte',
                  value: entry.telainiScorte?.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateEntry(entry.copyWith(
                      telainiScorte: int.tryParse(value),
                    ));
                  },
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
          SizedBox(height: 16),
          
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
              value: entry.tipoProblema,
              onChanged: (value) {
                _updateEntry(entry.copyWith(tipoProblema: value));
              },
            ),
          SizedBox(height: 16),
          
          // Notes section
          _buildSectionTitle('Note'),
          _buildTextField(
            label: 'Note aggiuntive',
            value: entry.note,
            maxLines: 3,
            onChanged: (value) {
              _updateEntry(entry.copyWith(note: value));
            },
          ),
          SizedBox(height: 32),
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
  
  Widget _buildTextField({
    required String label,
    String? value,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: TextEditingController(text: value),
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