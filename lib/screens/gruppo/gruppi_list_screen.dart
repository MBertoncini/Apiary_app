import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/gruppo.dart';
import '../../services/gruppo_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/drawer_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';

class GruppiListScreen extends StatefulWidget {
  @override
  _GruppiListScreenState createState() => _GruppiListScreenState();
}

class _GruppiListScreenState extends State<GruppiListScreen> {
  bool _isRefreshing = false;
  bool _cacheChecked = false;
  List<Gruppo> _gruppi = [];
  List<InvitoGruppo> _inviti = [];
  String? _errorMessage;
  late GruppoService _gruppoService;
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    _gruppoService = GruppoService(apiService, storageService);
    _storageService = storageService;

    _loadData();
  }

  Future<void> _loadData() async {
    _errorMessage = null;

    // Phase 1: cache — read before any setState so skeleton doesn't flash
    final cachedGruppi = await _storageService.getStoredData('gruppi');
    if (cachedGruppi.isNotEmpty) {
      _gruppi = cachedGruppi.map((e) => Gruppo.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (mounted) setState(() { _isRefreshing = true; _cacheChecked = true; });

    // Phase 2: API — gruppi + inviti
    try {
      final results = await Future.wait([
        _gruppoService.getGruppi(),
        _gruppoService.getInvitiRicevuti(),
      ]);

      final nuoviGruppi = results[0] as List<Gruppo>;
      final nuoviInviti = results[1] as List<InvitoGruppo>;

      // Salva gruppi nella cache
      await _storageService.saveData('gruppi', nuoviGruppi.map((g) => g.toJson()).toList());

      // Notifica per inviti nuovi mai visti prima
      try {
        final storedIds = await _storageService.getStoredData('seen_inviti_ids');
        final seenIds = Set<int>.from(
          storedIds.map((e) => e is int ? e : int.tryParse(e.toString()) ?? -1),
        );
        for (final invito in nuoviInviti) {
          if (!seenIds.contains(invito.id)) {
            await NotificationService().showInvitazioneGruppoNotification(
              invitoId: invito.id,
              gruppoNome: invito.gruppoNome,
              invitatoDaUsername: invito.invitatoDaUsername,
            );
          }
        }
        await _storageService.saveData('seen_inviti_ids', nuoviInviti.map((i) => i.id).toList());
      } catch (e) {
        debugPrint('Errore notifiche inviti: $e');
      }

      if (mounted) {
        _gruppi = nuoviGruppi;
        _inviti = nuoviInviti;
      }
    } catch (e) {
      if (_gruppi.isEmpty) {
        _errorMessage = 'Errore nel caricamento dei dati: ${e.toString()}';
      }
      debugPrint('Errore caricamento gruppi: $e');
    }

    if (mounted) setState(() { _isRefreshing = false; });
  }

  void _navigateToGruppoDetail(int gruppoId) {
    Navigator.of(context).pushNamed(
      AppConstants.gruppoDetailRoute,
      arguments: gruppoId,
    ).then((_) {
      // Aggiorna i dati quando torna dalla schermata di dettaglio
      _loadData();
    });
  }

  void _navigateToCreateGruppo() {
    Navigator.of(context).pushNamed(
      AppConstants.gruppoCreateRoute,
    ).then((_) {
      // Aggiorna i dati quando torna dalla schermata di creazione
      _loadData();
    });
  }

  Future<void> _handleInvito(InvitoGruppo invito, bool accept) async {
    try {
      final s = Provider.of<LanguageService>(context, listen: false).strings;
      if (accept) {
        await _gruppoService.accettaInvito(invito.token);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.gruppiInvitoAccettato),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
      } else {
        await _gruppoService.rifiutaInvito(invito.token);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.gruppiInvitoRifiutato),
          ),
        );
      }

      // Ricarica i dati
      _loadData();
    } catch (e) {
      if (!mounted) return;
      final s = Provider.of<LanguageService>(context, listen: false).strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.gruppiInvitoError(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    }
  }

  Widget _buildInvitiSection() {
    if (_inviti.isEmpty) {
      return Container();
    }
    final s = Provider.of<LanguageService>(context, listen: false).strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            s.gruppiInvitiRicevuti,
            style: ThemeConstants.subheadingStyle,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _inviti.length,
          itemBuilder: (context, index) {
            final invito = _inviti[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: ThemeConstants.primaryColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            invito.gruppoNome,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.gruppiInvitatoDa(invito.invitatoDaUsername, invito.getRuoloPropDisplay()),
                      style: TextStyle(
                        color: ThemeConstants.textSecondaryColor,
                      ),
                    ),
                    Text(
                      s.gruppiDataInvio(DateFormatter.formatDate(invito.dataInvio)),
                      style: TextStyle(
                        color: ThemeConstants.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      s.gruppiScadeIl(DateFormatter.formatDate(invito.dataScadenza)),
                      style: TextStyle(
                        color: ThemeConstants.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _handleInvito(invito, false),
                          child: Text(s.gruppiBtnRifiuta),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ThemeConstants.errorColor,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _handleInvito(invito, true),
                          child: Text(s.gruppiBtnAccetta),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Divider(height: 32),
      ],
    );
  }

  // Modifica al metodo _buildGruppiList in gruppi_list_screen.dart

  Widget _buildGruppiList() {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    try {
      if (_gruppi.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group_outlined,
                size: 64,
                color: ThemeConstants.textSecondaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                s.gruppiNoMembro,
                style: TextStyle(
                  color: ThemeConstants.textSecondaryColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text(s.gruppiBtnCrea),
                onPressed: _navigateToCreateGruppo,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        itemCount: _gruppi.length,
        itemBuilder: (context, index) {
          try {
            final gruppo = _gruppi[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => _navigateToGruppoDetail(gruppo.id),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: ThemeConstants.primaryColor,
                            backgroundImage: gruppo.immagineProfilo != null
                                ? CachedNetworkImageProvider(gruppo.immagineProfilo!)
                                : null,
                            child: gruppo.immagineProfilo == null
                                ? Text(
                                    gruppo.nome.isNotEmpty ? gruppo.nome[0].toUpperCase() : 'G',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gruppo.nome,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (gruppo.descrizione != null && gruppo.descrizione!.isNotEmpty)
                                  Text(
                                    gruppo.descrizione!,
                                    style: TextStyle(
                                      color: ThemeConstants.textSecondaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            s.gruppiMembriCount(gruppo.getMembriCount()),
                            style: TextStyle(
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                          SizedBox(width: 16),
                          Icon(
                            Icons.hive,
                            size: 16,
                            color: ThemeConstants.textSecondaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            s.gruppiApiariCondivisi(gruppo.getApiariCount()),
                            style: TextStyle(
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          } catch (e) {
            debugPrint('Errore nella costruzione della card per il gruppo all\'indice $index: $e');
            return ListTile(
              title: Text(s.gruppiErrLoading),
              subtitle: Text('$e'),
              textColor: ThemeConstants.errorColor,
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Errore globale in _buildGruppiList: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: ThemeConstants.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              s.gruppiErrLoadingGruppi,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$e',
              style: TextStyle(fontSize: 12, color: ThemeConstants.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: Text(s.gruppiBtnRiprova),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.gruppiTitle),
        actions: [],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.gruppiListRoute),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: !_cacheChecked
                  ? const SizedBox.shrink()
                  : _isRefreshing && _gruppi.isEmpty && _inviti.isEmpty
                  ? const SkeletonListView(itemCount: 4)
                  : _errorMessage != null
                      ? ErrorDisplayWidget(
                          errorMessage: _errorMessage!,
                          onRetry: _loadData,
                        )
                      : SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInvitiSection(),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  s.gruppiTuoiGruppi,
                                  style: ThemeConstants.subheadingStyle,
                                ),
                              ),
                              _buildGruppiList(),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateGruppo,
        child: Icon(Icons.add),
        tooltip: s.gruppiFabTooltip,
      ),
    );
  }
}