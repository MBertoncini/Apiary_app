// lib/screens/attrezzatura/attrezzatura_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/attrezzatura.dart';
import '../../models/spesa_attrezzatura.dart';
import '../../models/manutenzione.dart';
import '../../services/attrezzatura_service.dart';
import '../../services/api_service.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';

class AttrezzaturaDetailScreen extends StatefulWidget {
  final int attrezzaturaId;

  AttrezzaturaDetailScreen({required this.attrezzaturaId});

  @override
  _AttrezzaturaDetailScreenState createState() => _AttrezzaturaDetailScreenState();
}

class _AttrezzaturaDetailScreenState extends State<AttrezzaturaDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Attrezzatura? _attrezzatura;
  List<SpesaAttrezzatura> _spese = [];
  List<Manutenzione> _manutenzioni = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final service = AttrezzaturaService(apiService);

      final attrezzatura = await service.getAttrezzatura(widget.attrezzaturaId);

      // Carica spese e manutenzioni in parallelo
      List<SpesaAttrezzatura> spese = [];
      List<Manutenzione> manutenzioni = [];

      try {
        spese = await service.getSpeseAttrezzatura(widget.attrezzaturaId);
      } catch (e) {
        debugPrint('Errore caricamento spese: $e');
      }

      try {
        manutenzioni = await service.getManutenzioniAttrezzatura(widget.attrezzaturaId);
      } catch (e) {
        debugPrint('Errore caricamento manutenzioni: $e');
      }

      setState(() {
        _attrezzatura = attrezzatura;
        _spese = spese;
        _manutenzioni = manutenzioni;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore durante il caricamento: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_attrezzatura?.nome ?? 'Dettaglio Attrezzatura'),
        bottom: _attrezzatura != null
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Info'),
                  Tab(text: 'Spese'),
                  Tab(text: 'Manutenzioni'),
                ],
              )
            : null,
        actions: [
          if (_attrezzatura != null) ...[
            IconButton(
              icon: Icon(Icons.edit),
              tooltip: 'Modifica',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppConstants.attrezzaturaCreateRoute,
                  arguments: _attrezzatura!.id,
                ).then((_) => _loadData());
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: 'Elimina',
              onPressed: _confirmDelete,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? LoadingWidget()
          : _errorMessage != null
              ? ErrorDisplayWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadData,
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(),
                    _buildSpeseTab(),
                    _buildManutenzioniTab(),
                  ],
                ),
      floatingActionButton: _attrezzatura != null
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              child: Icon(Icons.add),
              tooltip: 'Aggiungi',
            )
          : null,
    );
  }

  Widget _buildInfoTab() {
    if (_attrezzatura == null) return SizedBox();

    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principale info
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: _getStatoColor(_attrezzatura!.stato).withOpacity(0.2),
                          child: Icon(
                            Icons.build,
                            size: 30,
                            color: _getStatoColor(_attrezzatura!.stato),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _attrezzatura!.nome,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                _attrezzatura!.categoriaNome ?? 'Non categorizzato',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatoColor(_attrezzatura!.stato).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _attrezzatura!.getStatoDisplay(),
                            style: TextStyle(
                              color: _getStatoColor(_attrezzatura!.stato),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 32),
                    if (_attrezzatura!.condizione != null)
                      _buildInfoRow(Icons.star, 'Condizione', _attrezzatura!.getCondizioneDisplay()),
                    if (_attrezzatura!.descrizione != null && _attrezzatura!.descrizione!.isNotEmpty)
                      _buildInfoRow(Icons.description, 'Descrizione', _attrezzatura!.descrizione!),
                    if (_attrezzatura!.marca != null && _attrezzatura!.marca!.isNotEmpty)
                      _buildInfoRow(Icons.branding_watermark, 'Marca', _attrezzatura!.marca!),
                    if (_attrezzatura!.modello != null && _attrezzatura!.modello!.isNotEmpty)
                      _buildInfoRow(Icons.model_training, 'Modello', _attrezzatura!.modello!),
                    if (_attrezzatura!.numeroSerie != null && _attrezzatura!.numeroSerie!.isNotEmpty)
                      _buildInfoRow(Icons.qr_code, 'N. Serie', _attrezzatura!.numeroSerie!),
                    _buildInfoRow(Icons.inventory_2, 'Quantità', '${_attrezzatura!.quantita}'),
                    if (_attrezzatura!.unitaMisura != null && _attrezzatura!.unitaMisura!.isNotEmpty)
                      _buildInfoRow(Icons.straighten, 'Unità Misura', _attrezzatura!.unitaMisura!),
                    if (_attrezzatura!.dataAcquisto != null)
                      _buildInfoRow(Icons.calendar_today, 'Data Acquisto',
                          formatDate.format(_attrezzatura!.dataAcquisto!)),
                    if (_attrezzatura!.prezzoAcquisto != null && _attrezzatura!.prezzoAcquisto! > 0)
                      _buildInfoRow(Icons.euro, 'Prezzo Acquisto',
                          formatCurrency.format(_attrezzatura!.prezzoAcquisto)),
                    if (_attrezzatura!.fornitore != null && _attrezzatura!.fornitore!.isNotEmpty)
                      _buildInfoRow(Icons.store, 'Fornitore', _attrezzatura!.fornitore!),
                    if (_attrezzatura!.garanziaFinoA != null)
                      _buildInfoRow(Icons.verified_user, 'Garanzia fino a',
                          formatDate.format(_attrezzatura!.garanziaFinoA!)),
                    if (_attrezzatura!.posizione != null && _attrezzatura!.posizione!.isNotEmpty)
                      _buildInfoRow(Icons.location_on, 'Posizione', _attrezzatura!.posizione!),
                    if (_attrezzatura!.apiarioNome != null)
                      _buildInfoRow(Icons.hive, 'Apiario', _attrezzatura!.apiarioNome!),
                    if (_attrezzatura!.condivisoConGruppo && _attrezzatura!.gruppoNome != null)
                      _buildInfoRow(Icons.group, 'Gruppo', _attrezzatura!.gruppoNome!),
                    if (_attrezzatura!.note != null && _attrezzatura!.note!.isNotEmpty)
                      _buildInfoRow(Icons.note, 'Note', _attrezzatura!.note!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card statistiche
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiche',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Spese Totali',
                            formatCurrency.format(_getTotalSpese()),
                            Icons.payments,
                            Colors.orange,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Manutenzioni',
                            '${_manutenzioni.length}',
                            Icons.build,
                            Colors.blue,
                          ),
                        ),
                      ],
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

  Widget _buildSpeseTab() {
    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');

    if (_spese.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessuna spesa registrata',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Aggiungi Spesa'),
              onPressed: () => _navigateToSpesaForm(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _spese.length,
        itemBuilder: (context, index) {
          final spesa = _spese[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.2),
                child: Icon(Icons.receipt, color: Colors.orange),
              ),
              title: Text(spesa.descrizione),
              subtitle: Text(
                '${spesa.getTipoDisplay()} - ${formatDate.format(spesa.data)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatCurrency.format(spesa.importo),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primaryColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'Elimina spesa',
                    onPressed: () => _confirmDeleteSpesa(spesa),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildManutenzioniTab() {
    final formatCurrency = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');

    if (_manutenzioni.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Nessuna manutenzione registrata',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Aggiungi Manutenzione'),
              onPressed: () => _navigateToManutenzioneForm(),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _manutenzioni.length,
        itemBuilder: (context, index) {
          final manutenzione = _manutenzioni[index];
          final isInRitardo = manutenzione.isInRitardo();

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getManutenzioneColor(manutenzione.stato, isInRitardo)
                    .withOpacity(0.2),
                child: Icon(
                  Icons.build,
                  color: _getManutenzioneColor(manutenzione.stato, isInRitardo),
                ),
              ),
              title: Text(manutenzione.getTipoDisplay()),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (manutenzione.descrizione.isNotEmpty)
                    Text(
                      manutenzione.descrizione,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Row(
                    children: [
                      Text(
                        manutenzione.getStatoDisplay(),
                        style: TextStyle(
                          color: _getManutenzioneColor(manutenzione.stato, isInRitardo),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isInRitardo) ...[
                        SizedBox(width: 8),
                        Icon(Icons.warning, size: 16, color: Colors.red),
                        Text(' In ritardo', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                    ],
                  ),
                  Text(
                    'Programmata: ${formatDate.format(manutenzione.dataProgrammata)}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (manutenzione.costo != null && manutenzione.costo! > 0)
                    Text(
                      formatCurrency.format(manutenzione.costo),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ThemeConstants.primaryColor,
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'Elimina manutenzione',
                    onPressed: () => _confirmDeleteManutenzione(manutenzione),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  double _getTotalSpese() {
    return _spese.fold(0.0, (sum, spesa) => sum + spesa.importo);
  }

  Color _getStatoColor(String? stato) {
    switch (stato) {
      case 'disponibile':
        return Colors.green;
      case 'in_uso':
        return Colors.blue;
      case 'manutenzione':
        return Colors.orange;
      case 'dismesso':
        return Colors.grey;
      case 'prestato':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getManutenzioneColor(String stato, bool isInRitardo) {
    if (isInRitardo) return Colors.red;
    switch (stato) {
      case 'programmata':
        return Colors.blue;
      case 'in_corso':
        return Colors.orange;
      case 'completata':
        return Colors.green;
      case 'annullata':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.receipt, color: Colors.orange),
                title: Text('Aggiungi Spesa'),
                subtitle: Text('Registra una nuova spesa per questa attrezzatura'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToSpesaForm();
                },
              ),
              ListTile(
                leading: Icon(Icons.build, color: Colors.blue),
                title: Text('Aggiungi Manutenzione'),
                subtitle: Text('Programma o registra una manutenzione'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToManutenzioneForm();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSpesaForm() {
    Navigator.pushNamed(
      context,
      AppConstants.spesaAttrezzaturaCreateRoute,
      arguments: {
        'attrezzaturaId': widget.attrezzaturaId,
        'attrezzaturaNome': _attrezzatura?.nome,
        'condivisoConGruppo': _attrezzatura?.condivisoConGruppo ?? false,
        'gruppoId': _attrezzatura?.gruppo,
      },
    ).then((_) => _loadData());
  }

  void _navigateToManutenzioneForm() {
    Navigator.pushNamed(
      context,
      AppConstants.manutenzioneCreateRoute,
      arguments: {
        'attrezzaturaId': widget.attrezzaturaId,
        'attrezzaturaNome': _attrezzatura?.nome,
        'condivisoConGruppo': _attrezzatura?.condivisoConGruppo ?? false,
        'gruppoId': _attrezzatura?.gruppo,
      },
    ).then((_) => _loadData());
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Attrezzatura'),
        content: Text(
          'Sei sicuro di voler eliminare "${_attrezzatura?.nome}"?\n\n'
          'Verranno eliminate anche tutte le spese e manutenzioni associate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAttrezzatura();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttrezzatura() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final service = AttrezzaturaService(apiService);

      await service.deleteAttrezzatura(widget.attrezzaturaId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attrezzatura eliminata con successo')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  void _confirmDeleteSpesa(SpesaAttrezzatura spesa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Spesa'),
        content: Text(
          'Sei sicuro di voler eliminare la spesa "${spesa.descrizione}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = Provider.of<ApiService>(this.context, listen: false);
                final service = AttrezzaturaService(apiService);
                await service.deleteSpesaAttrezzatura(spesa.id);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Spesa eliminata con successo')),
                );

                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteManutenzione(Manutenzione manutenzione) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Elimina Manutenzione'),
        content: Text(
          'Sei sicuro di voler eliminare la manutenzione "${manutenzione.getTipoDisplay()}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final apiService = Provider.of<ApiService>(this.context, listen: false);
                final service = AttrezzaturaService(apiService);
                await service.deleteManutenzione(manutenzione.id);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Manutenzione eliminata con successo')),
                );

                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
