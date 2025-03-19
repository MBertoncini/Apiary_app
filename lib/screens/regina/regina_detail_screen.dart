import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_widget.dart';

class ReginaDetailScreen extends StatefulWidget {
  final int reginaId;

  const ReginaDetailScreen({Key? key, required this.reginaId}) : super(key: key);

  @override
  _ReginaDetailScreenState createState() => _ReginaDetailScreenState();
}

class _ReginaDetailScreenState extends State<ReginaDetailScreen> {
  late ApiService _apiService;
  late Future<dynamic> _reginaFuture;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _loadRegina();
  }

  void _loadRegina() {
    _reginaFuture = _apiService.get('${ApiConstants.regineUrl}${widget.reginaId}/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dettaglio Regina'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _loadRegina();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: _reginaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingWidget();
          } else if (snapshot.hasError) {
            return CustomErrorWidget(
              errorMessage: 'Errore nel caricamento della regina: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _loadRegina();
                });
              },
            );
          } else if (!snapshot.hasData) {
            return CustomErrorWidget(
              errorMessage: 'Nessun dato trovato per questa regina',
              onRetry: () {
                setState(() {
                  _loadRegina();
                });
              },
            );
          } else {
            final regina = snapshot.data;
            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReginaHeader(regina),
                  SizedBox(height: 24),
                  _buildInfoSection('Informazioni Generali', [
                    _buildInfoRow('Arnia', 'Arnia ${regina['arnia_numero'] ?? 'N/D'}'),
                    _buildInfoRow('Razza', _getRazzaDisplay(regina['razza'])),
                    _buildInfoRow('Origine', _getOrigineDisplay(regina['origine'])),
                    if (regina['data_nascita'] != null)
                      _buildInfoRow('Data nascita', regina['data_nascita']),
                    _buildInfoRow('Data introduzione', regina['data_introduzione']),
                    _buildInfoRow('Fecondata', regina['fecondata'] ? 'Sì' : 'No'),
                    _buildInfoRow('Selezionata', regina['selezionata'] ? 'Sì' : 'No'),
                  ]),
                  SizedBox(height: 16),
                  _buildInfoSection('Marcatura', [
                    _buildInfoRow('Marcata', regina['marcata'] ? 'Sì' : 'No'),
                    if (regina['marcata'])
                      _buildInfoRow('Colore marcatura', _getColoreMarcaturaDisplay(regina['colore_marcatura'])),
                    if (regina['codice_marcatura'] != null && regina['codice_marcatura'].isNotEmpty)
                      _buildInfoRow('Codice marcatura', regina['codice_marcatura']),
                  ]),
                  if (regina['docilita'] != null || 
                      regina['produttivita'] != null || 
                      regina['resistenza_malattie'] != null || 
                      regina['tendenza_sciamatura'] != null) ...[
                    SizedBox(height: 16),
                    _buildRatingSection('Valutazioni', [
                      if (regina['docilita'] != null)
                        _buildRatingRow('Docilità', regina['docilita']),
                      if (regina['produttivita'] != null)
                        _buildRatingRow('Produttività', regina['produttivita']),
                      if (regina['resistenza_malattie'] != null)
                        _buildRatingRow('Resistenza malattie', regina['resistenza_malattie']),
                      if (regina['tendenza_sciamatura'] != null)
                        _buildRatingRow('Tendenza sciamatura', regina['tendenza_sciamatura']),
                    ]),
                  ],
                  if (regina['note'] != null && regina['note'].isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildInfoSection('Note', [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(regina['note']),
                      ),
                    ]),
                  ],
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.edit),
                        label: Text('Modifica'),
                        onPressed: () {
                          // Navigazione alla schermata di modifica
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Funzionalità di modifica non ancora implementata')),
                          );
                        },
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.swap_horiz),
                        label: Text('Sostituisci'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        onPressed: () {
                          // Navigazione alla schermata di sostituzione
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Funzionalità di sostituzione non ancora implementata')),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildReginaHeader(dynamic regina) {
    Color reginaColor;
    
    // Colore basato sul colore di marcatura
    switch (regina['colore_marcatura']) {
      case 'bianco':
        reginaColor = Colors.white;
        break;
      case 'giallo':
        reginaColor = Colors.amber;
        break;
      case 'rosso':
        reginaColor = Colors.red;
        break;
      case 'verde':
        reginaColor = Colors.green;
        break;
      case 'blu':
        reginaColor = Colors.blue;
        break;
      case 'non_marcata':
      default:
        reginaColor = Colors.grey;
        break;
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: reginaColor,
              child: regina['marcata'] 
                  ? Icon(Icons.local_florist, color: _getContrastColor(reginaColor), size: 36)
                  : Icon(Icons.local_florist_outlined, color: _getContrastColor(reginaColor), size: 36),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regina dell\'arnia ${regina['arnia_numero'] ?? 'N/D'}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getRazzaDisplay(regina['razza']),
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  if (regina['data_nascita'] != null) ...[
                    Text(
                      'Età: ${_calculateAge(regina['data_nascita'])}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(String title, List<Widget> children) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: index < rating ? Colors.amber : Colors.grey,
                  size: 20,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getRazzaDisplay(String razza) {
    switch (razza) {
      case 'ligustica':
        return 'Apis mellifera ligustica (Italiana)';
      case 'carnica':
        return 'Apis mellifera carnica (Carnica)';
      case 'buckfast':
        return 'Buckfast';
      case 'caucasica':
        return 'Apis mellifera caucasica';
      case 'sicula':
        return 'Apis mellifera sicula (Siciliana)';
      case 'ibrida':
        return 'Ibrida';
      case 'altro':
        return 'Altro';
      default:
        return razza;
    }
  }

  String _getOrigineDisplay(String origine) {
    switch (origine) {
      case 'acquistata':
        return 'Acquistata';
      case 'allevata':
        return 'Allevata';
      case 'sciamatura':
        return 'Sciamatura Naturale';
      case 'emergenza':
        return 'Celle di Emergenza';
      case 'sconosciuta':
        return 'Sconosciuta';
      default:
        return origine;
    }
  }

  String _getColoreMarcaturaDisplay(String colore) {
    switch (colore) {
      case 'bianco':
        return 'Bianco (anni terminanti in 1,6)';
      case 'giallo':
        return 'Giallo (anni terminanti in 2,7)';
      case 'rosso':
        return 'Rosso (anni terminanti in 3,8)';
      case 'verde':
        return 'Verde (anni terminanti in 4,9)';
      case 'blu':
        return 'Blu (anni terminanti in 5,0)';
      case 'non_marcata':
        return 'Non Marcata';
      default:
        return colore;
    }
  }

  String _calculateAge(String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final now = DateTime.now();
      
      final difference = now.difference(birthDate);
      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      
      if (years > 0) {
        return '$years ${years == 1 ? 'anno' : 'anni'}';
      } else if (months > 0) {
        return '$months ${months == 1 ? 'mese' : 'mesi'}';
      } else {
        return '${difference.inDays} ${difference.inDays == 1 ? 'giorno' : 'giorni'}';
      }
    } catch (e) {
      return 'N/D';
    }
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calcola se il testo dovrebbe essere chiaro o scuro
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}