import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../models/gruppo.dart';
import '../../services/gruppo_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../l10n/app_strings.dart';
import '../../utils/date_formatters.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_widgets.dart';

class GruppoDetailScreen extends StatefulWidget {
  final int gruppoId;

  GruppoDetailScreen({required this.gruppoId});

  @override
  _GruppoDetailScreenState createState() => _GruppoDetailScreenState();
}

class _GruppoDetailScreenState extends State<GruppoDetailScreen>
    with TickerProviderStateMixin {
  // ignore: unused_field
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _cacheChecked = false;
  bool _isUploadingImage = false;
  Gruppo? _gruppo;
  List<dynamic> _apiariCondivisi = [];
  List<InvitoGruppo> _inviti = [];
  String? _errorMessage;
  late GruppoService _gruppoService;
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isAdmin = false;
  bool _isCreator = false;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);
    _gruppoService = GruppoService(apiService, storageService);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  Future<void> _loadData() async {
    _errorMessage = null;

    // Fase 1: cache — read before any setState so skeleton doesn't flash
    if (_gruppo == null) {
      try {
        final storageService = Provider.of<StorageService>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);
        final cachedGruppi = await storageService.getStoredData('gruppi');
        final cached = cachedGruppi.cast<Map<String, dynamic>>().firstWhere(
          (g) => g['id'] == widget.gruppoId,
          orElse: () => <String, dynamic>{},
        );
        if (cached.isNotEmpty) {
          final gruppoBase = Gruppo.fromJson(cached);

          // Leggi anche membri e apiari dalla cache
          List<dynamic> cachedMembri = [];
          List<dynamic> cachedApiari = [];
          try {
            final rawMembri = await storageService.getStoredData('gruppo_membri_${widget.gruppoId}');
            if (rawMembri.isNotEmpty) {
              cachedMembri = rawMembri.cast<Map<String, dynamic>>()
                  .map((m) => MembroGruppo.fromJson(m))
                  .toList();
            }
          } catch (_) {}
          try {
            cachedApiari = await storageService.getStoredData('gruppo_apiari_${widget.gruppoId}');
          } catch (_) {}

          _gruppo = Gruppo(
            id: gruppoBase.id,
            nome: gruppoBase.nome,
            descrizione: gruppoBase.descrizione,
            dataCreazione: gruppoBase.dataCreazione,
            creatoreId: gruppoBase.creatoreId,
            creatoreName: gruppoBase.creatoreName,
            membri: cachedMembri,
            immagineProfilo: gruppoBase.immagineProfilo,
            apiariIds: gruppoBase.apiariIds,
            membriCountFromApi: gruppoBase.membriCountFromApi,
            apiariCountFromApi: gruppoBase.apiariCountFromApi,
          );
          _apiariCondivisi = cachedApiari;

          // Imposta admin/creator dalla cache così i tab sono già corretti
          final user = authService.currentUser;
          if (user != null) {
            _isAdmin = _gruppo!.isAdmin(user.id);
            _isCreator = _gruppo!.isCreator(user.id);
            final neededTabs = _isAdmin ? 3 : 2;
            if (_tabController.length != neededTabs) {
              _tabController.removeListener(_onTabChanged);
              _tabController.dispose();
              _tabController = TabController(length: neededTabs, vsync: this);
              _tabController.addListener(_onTabChanged);
            }
          }
        }
      } catch (_) {}
    }
    if (mounted) setState(() { _isRefreshing = true; _cacheChecked = true; });

    try {
      final results = await Future.wait([
        _gruppoService.getGruppoDetail(widget.gruppoId),
        _gruppoService.getApiariGruppo(widget.gruppoId),
      ]);

      final gruppo = results[0] as Gruppo;
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      final newIsAdmin = user != null && gruppo.isAdmin(user.id);
      final newIsCreator = user != null && gruppo.isCreator(user.id);

      List<InvitoGruppo> inviti = [];
      if (newIsAdmin) {
        try {
          inviti = await _gruppoService.getGruppoInviti(widget.gruppoId);
        } catch (e) {
          debugPrint('Errore nel caricamento degli inviti: $e');
        }
      }

      // Reinitialise TabController if admin status changed (2 tabs → 3 tabs or vice versa)
      final neededTabs = newIsAdmin ? 3 : 2;
      if (_tabController.length != neededTabs) {
        _tabController.removeListener(_onTabChanged);
        _tabController.dispose();
        _tabController = TabController(length: neededTabs, vsync: this);
        _tabController.addListener(_onTabChanged);
      }

      setState(() {
        _gruppo = gruppo;
        _apiariCondivisi = results[1] is List ? results[1] as List : [];
        _inviti = inviti;
        _isAdmin = newIsAdmin;
        _isCreator = newIsCreator;
        _currentIndex = 0;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = _s.gruppoDetailDataLoadError;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  // ──────────────────────────────────────────────────────────
  // Immagine gruppo
  // ──────────────────────────────────────────────────────────

  Future<void> _pickAndUploadGruppoImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    setState(() => _isUploadingImage = true);
    try {
      final updatedGruppo = await _gruppoService.uploadGruppoImage(widget.gruppoId, File(picked.path));
      setState(() => _gruppo = Gruppo(
        id: _gruppo!.id,
        nome: _gruppo!.nome,
        descrizione: _gruppo!.descrizione,
        dataCreazione: _gruppo!.dataCreazione,
        creatoreId: _gruppo!.creatoreId,
        creatoreName: _gruppo!.creatoreName,
        membri: _gruppo!.membri,
        immagineProfilo: updatedGruppo.immagineProfilo,
        apiariIds: _gruppo!.apiariIds,
        membriCountFromApi: _gruppo!.membriCountFromApi,
        apiariCountFromApi: _gruppo!.apiariCountFromApi,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_s.gruppoDetailImmagineAggiornata),
          backgroundColor: ThemeConstants.successColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_s.msgErrorGeneric(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Navigation helpers
  // ──────────────────────────────────────────────────────────

  void _navigateToApiarioDetail(dynamic apiarioId) {
    int id;
    if (apiarioId is int) {
      id = apiarioId;
    } else if (apiarioId is String) {
      id = int.tryParse(apiarioId) ?? 0;
    } else {
      id = 0;
    }
    if (id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.gruppoDetailDataLoadError),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      return;
    }
    Navigator.of(context).pushNamed(AppConstants.apiarioDetailRoute, arguments: id);
  }

  void _navigateToEditGruppo() {
    if (_gruppo == null) return;
    Navigator.of(context)
        .pushNamed(AppConstants.gruppoCreateRoute, arguments: _gruppo)
        .then((_) => _loadData());
  }

  void _navigateToInvita() {
    Navigator.of(context)
        .pushNamed(AppConstants.gruppoInvitoRoute, arguments: widget.gruppoId)
        .then((_) => _loadData());
  }

  // ──────────────────────────────────────────────────────────
  // Dialogs – Cambia ruolo
  // ──────────────────────────────────────────────────────────

  Future<void> _showCambiaRuoloDialog(
      BuildContext context, dynamic membro, int membroId) async {
    String currentRole = 'viewer';
    if (membro is MembroGruppo) {
      currentRole = membro.ruolo;
    } else if (membro is Map<String, dynamic>) {
      currentRole = membro['ruolo'] ?? 'viewer';
    }

    final selectedRole = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String tempRole = currentRole;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(_s.gruppoDetailCambiaRuoloTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(_s.gruppoDetailRuoloAdmin),
                    subtitle: Text(_s.gruppoDetailRuoloAdminDesc),
                    value: 'admin',
                    groupValue: tempRole,
                    onChanged: (v) => setDialogState(() => tempRole = v!),
                  ),
                  RadioListTile<String>(
                    title: Text(_s.gruppoDetailRuoloEditor),
                    subtitle: Text(_s.gruppoDetailRuoloEditorDesc),
                    value: 'editor',
                    groupValue: tempRole,
                    onChanged: (v) => setDialogState(() => tempRole = v!),
                  ),
                  RadioListTile<String>(
                    title: Text(_s.gruppoDetailRuoloViewer),
                    subtitle: Text(_s.gruppoDetailRuoloViewerDesc),
                    value: 'viewer',
                    groupValue: tempRole,
                    onChanged: (v) => setDialogState(() => tempRole = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(_s.dialogCancelBtn),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempRole),
                  child: Text(_s.gruppoFormBtnSalva),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedRole == null || selectedRole == currentRole) return;

    setState(() => _isLoading = true);
    try {
      await _gruppoService.updateMembroRuolo(
          widget.gruppoId, membroId, selectedRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.gruppoDetailRuoloUpdated)),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.msgErrorGeneric(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Dialogs – Rimuovi membro
  // ──────────────────────────────────────────────────────────

  Future<void> _showRimuoviMembroDialog(BuildContext context, dynamic membro,
      int membroId, String username) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_s.gruppoDetailRimuoviTitle),
            content: Text(_s.gruppoDetailRimuoviMsg(username)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_s.dialogCancelBtn),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: ThemeConstants.errorColor),
                child: Text(_s.gruppoDetailRimuoviBtnConfirm),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _gruppoService.removeMembro(widget.gruppoId, membroId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.gruppoDetailRimosso(username))),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.msgErrorGeneric(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Dialogs – Elimina gruppo
  // ──────────────────────────────────────────────────────────

  Future<void> _showDeleteGruppoDialog() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_s.gruppoDetailEliminaTitle),
            content: Text(_s.gruppoDetailEliminaMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_s.dialogCancelBtn),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: ThemeConstants.errorColor),
                child: Text(_s.btnDeleteCaps),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _gruppoService.deleteGruppo(widget.gruppoId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.gruppoDetailEliminato)),
      );
      Navigator.of(context)
          .pushReplacementNamed(AppConstants.gruppiListRoute);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.msgErrorGeneric(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Dialogs – Lascia gruppo
  // ──────────────────────────────────────────────────────────

  Future<void> _showLeaveGroupDialog() async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_s.gruppoDetailLasciaTitle),
            content: Text(_s.gruppoDetailLasciaMsg(_gruppo!.nome)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_s.dialogCancelBtn),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: ThemeConstants.errorColor),
                child: Text(_s.gruppoDetailLasciaBtnConfirm),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    // Find current user's MembroGruppo ID
    int membroId = 0;
    for (var m in _gruppo!.membri) {
      if (m is MembroGruppo && m.utenteId == user.id) {
        membroId = m.id;
        break;
      } else if (m is Map<String, dynamic>) {
        int utenteId = 0;
        final utente = m['utente'];
        if (utente is int) {
          utenteId = utente;
        } else if (utente is Map) {
          utenteId = utente['id'] ?? 0;
        }
        if (utenteId == user.id) {
          final id = m['id'];
          if (id is int) {
            membroId = id;
          } else if (id is String) {
            membroId = int.tryParse(id) ?? 0;
          }
          break;
        }
      }
    }

    if (membroId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.gruppoDetailImpossibileTrovareProf),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _gruppoService.removeMembro(widget.gruppoId, membroId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.gruppoDetailLasciato)),
      );
      Navigator.of(context)
          .pushReplacementNamed(AppConstants.gruppiListRoute);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.msgErrorGeneric(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Annulla invito
  // ──────────────────────────────────────────────────────────

  Future<void> _annullaInvito(InvitoGruppo invito) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_s.gruppoDetailAnnullaInvitoTitle),
            content: Text(_s.gruppoDetailAnnullaInvitoMsg(invito.email)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_s.dialogCancelBtn),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                    foregroundColor: ThemeConstants.errorColor),
                child: Text(_s.gruppoDetailAnnullaBtnConfirm),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await _gruppoService.annullaInvito(widget.gruppoId, invito.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.gruppoDetailInvitoAnnullato)),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.msgErrorGeneric(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    }
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    final List<Tab> tabs = [
      Tab(icon: Icon(Icons.people), text: s.gruppoDetailTabMembri),
      Tab(icon: Icon(Icons.hive), text: s.gruppoDetailTabApiari),
      if (_isAdmin) Tab(icon: Icon(Icons.mail_outline), text: s.gruppoDetailTabInviti),
    ];

    final List<Widget> tabViews = [
      _buildMembriTab(),
      _buildApiariTab(),
      if (_isAdmin) _buildInvitiTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: (_isAdmin || _isCreator) && !_isUploadingImage
                  ? _pickAndUploadGruppoImage
                  : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: ThemeConstants.primaryColor.withOpacity(0.2),
                    backgroundImage: (_gruppo?.immagineProfilo != null)
                        ? CachedNetworkImageProvider(_gruppo!.immagineProfilo!)
                        : null,
                    child: (_gruppo?.immagineProfilo == null)
                        ? Text(
                            (_gruppo?.nome.isNotEmpty == true)
                                ? _gruppo!.nome[0].toUpperCase()
                                : 'G',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  if (_isAdmin || _isCreator)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ThemeConstants.primaryColor,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: _isUploadingImage
                            ? const Padding(
                                padding: EdgeInsets.all(2),
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                              )
                            : const Icon(Icons.camera_alt, size: 8, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(_gruppo?.nome ?? s.gruppoDetailDefaultTitle),
          ],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: Icon(Icons.person_add),
              onPressed: _navigateToInvita,
              tooltip: s.gruppoDetailTooltipInvita,
            ),
          if (_isAdmin || _isCreator)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: _navigateToEditGruppo,
              tooltip: s.gruppoDetailTooltipModifica,
            ),
        ],
        bottom: _gruppo == null || _errorMessage != null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: tabs,
                onTap: (index) {
                  setState(() => _currentIndex = index);
                },
              ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          if (_isRefreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: !_cacheChecked
                ? const SizedBox.shrink()
                : _isRefreshing && _gruppo == null
                ? const SkeletonDetailHeader()
                : _errorMessage != null
                    ? ErrorDisplayWidget(
                        errorMessage: _errorMessage!,
                        onRetry: _loadData,
                      )
                    : _gruppo == null
                        ? Center(child: Text(s.gruppoDetailNotFound))
                        : IndexedStack(
                            index: _currentIndex,
                            children: tabViews,
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _gruppo == null
          ? null
          : BottomAppBar(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _isCreator
                    ? ElevatedButton.icon(
                        onPressed: _showDeleteGruppoDialog,
                        icon: Icon(Icons.delete_forever),
                        label: Text(s.gruppoDetailBtnElimina),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThemeConstants.errorColor,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: _showLeaveGroupDialog,
                        icon: Icon(Icons.exit_to_app),
                        label: Text(s.gruppoDetailBtnLascia),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ThemeConstants.errorColor,
                          side: BorderSide(color: ThemeConstants.errorColor),
                        ),
                      ),
              ),
            ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Tab – Membri
  // ──────────────────────────────────────────────────────────

  Widget _buildMembriTab() {
    if (_gruppo == null) return Container();

    if (_gruppo!.membri.isEmpty) {
      return Center(child: Text(_s.gruppoDetailNoMembri));
    }

    return ListView.builder(
      itemCount: _gruppo!.membri.length,
      itemBuilder: (context, index) {
        final membro = _gruppo!.membri[index];

        String username = '';
        String ruolo = '';
        bool isCreatorMember = false;
        int membroId = 0;
        int utenteId = 0;

        String? membroImmagine;
        if (membro is MembroGruppo) {
          username = membro.username;
          ruolo = membro.ruolo;
          membroId = membro.id;
          utenteId = membro.utenteId;
          membroImmagine = membro.immagineProfilo;
        } else if (membro is Map<String, dynamic>) {
          username =
              membro['username'] ?? membro['utente_username'] ?? _s.gruppoDetailMembroNonValido;
          ruolo = membro['ruolo'] ?? 'viewer';
          membroImmagine = membro['immagine_profilo'] as String?;
          final rawId = membro['id'];
          if (rawId is int) {
            membroId = rawId;
          } else if (rawId is String) {
            membroId = int.tryParse(rawId) ?? 0;
          }
          final utente = membro['utente'];
          if (utente is int) {
            utenteId = utente;
          } else if (utente is String) {
            utenteId = int.tryParse(utente) ?? 0;
          } else if (utente is Map) {
            utenteId = utente['id'] ?? 0;
          }
        } else {
          return ListTile(
            title: Text(_s.gruppoDetailMembroNonValido),
          );
        }

        isCreatorMember = utenteId == _gruppo!.creatoreId;

        // Don't show admin menu for the creator
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: ThemeConstants.primaryColor,
            backgroundImage: membroImmagine != null
                ? CachedNetworkImageProvider(membroImmagine)
                : null,
            child: membroImmagine == null
                ? Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          title: Text(username),
          subtitle: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getRuoloDisplay(ruolo),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.primaryColor,
                  ),
                ),
              ),
              if (isCreatorMember) ...[
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _s.gruppoDetailRuoloCreatore,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: _isAdmin && !isCreatorMember
              ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'cambiaRuolo') {
                      _showCambiaRuoloDialog(context, membro, membroId);
                    } else if (value == 'rimuovi') {
                      _showRimuoviMembroDialog(
                          context, membro, membroId, username);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'cambiaRuolo',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text(_s.gruppoDetailPopupCambiaRuolo),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'rimuovi',
                      child: Row(
                        children: [
                          Icon(Icons.person_remove,
                              size: 18,
                              color: ThemeConstants.errorColor),
                          SizedBox(width: 8),
                          Text(
                            _s.gruppoDetailPopupRimuovi,
                            style:
                                TextStyle(color: ThemeConstants.errorColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  String _getRuoloDisplay(String ruolo) {
    switch (ruolo) {
      case 'admin':
        return _s.gruppoDetailRuoloAdmin;
      case 'editor':
        return _s.gruppoDetailRuoloEditor;
      case 'viewer':
        return _s.gruppoDetailRuoloViewer;
      default:
        return ruolo;
    }
  }

  // ──────────────────────────────────────────────────────────
  // Tab – Apiari
  // ──────────────────────────────────────────────────────────

  Widget _buildApiariTab() {
    if (_apiariCondivisi.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hive_outlined,
                size: 64,
                color: ThemeConstants.textSecondaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _s.gruppoDetailNoApiariCondivisi,
              style: TextStyle(
                  color: ThemeConstants.textSecondaryColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _apiariCondivisi.length,
      itemBuilder: (context, index) {
        final apiario = _apiariCondivisi[index];
        if (apiario is! Map<String, dynamic>) {
          return SizedBox.shrink();
        }
        final nome = apiario['nome'] ?? _s.gruppoDetailDefaultTitle;
        final posizione =
            apiario['posizione'] ?? _s.gruppoDetailApiarioNoPos;
        final proprietarioNome =
            apiario['proprietario_username'] ?? 'N/D';
        final apiarioId = apiario['id'];

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: apiarioId != null
                ? () => _navigateToApiarioDetail(apiarioId)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nome,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    posizione,
                    style: TextStyle(
                        color: ThemeConstants.textSecondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person,
                          size: 16,
                          color: ThemeConstants.textSecondaryColor),
                      SizedBox(width: 4),
                      Text(
                        '${_s.gruppoDetailApiarioProprietario}: $proprietarioNome',
                        style: TextStyle(
                            color: ThemeConstants.textSecondaryColor,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────
  // Tab – Inviti (solo admin)
  // ──────────────────────────────────────────────────────────

  Widget _buildInvitiTab() {
    if (_inviti.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline,
                size: 64,
                color: ThemeConstants.textSecondaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              _s.gruppoDetailNoInviti,
              style: TextStyle(
                  color: ThemeConstants.textSecondaryColor, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.person_add),
              label: Text(_s.gruppoDetailBtnInvitaMembro),
              onPressed: _navigateToInvita,
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.only(bottom: 80),
          itemCount: _inviti.length,
          itemBuilder: (context, index) {
            final invito = _inviti[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      ThemeConstants.primaryColor.withOpacity(0.15),
                  child: Icon(Icons.email,
                      color: ThemeConstants.primaryColor),
                ),
                title: Text(invito.email),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_s.gruppoDetailInvitoRuoloLbl}: ${invito.getRuoloPropDisplay()}'),
                    Text(
                      '${_s.gruppoDetailInvitoScadeLbl}: ${DateFormatter.formatDate(invito.dataScadenza)}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: Icon(Icons.cancel,
                      color: ThemeConstants.errorColor),
                  tooltip: _s.gruppoDetailTooltipAnnullaInvito,
                  onPressed: () => _annullaInvito(invito),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _navigateToInvita,
            child: Icon(Icons.person_add),
            tooltip: _s.gruppoDetailTooltipInvita,
          ),
        ),
      ],
    );
  }
}
