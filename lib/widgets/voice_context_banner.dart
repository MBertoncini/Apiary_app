// lib/widgets/voice_context_banner.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';
import '../l10n/app_strings.dart';
import '../constants/theme_constants.dart';

class VoiceContextBanner extends StatefulWidget {
  final void Function(int id, String nome) onApiarioSelected;
  final bool isOnline;

  const VoiceContextBanner({
    Key? key,
    required this.onApiarioSelected,
    this.isOnline = true,
  }) : super(key: key);

  @override
  State<VoiceContextBanner> createState() => _VoiceContextBannerState();
}

class _VoiceContextBannerState extends State<VoiceContextBanner> {
  static const _prefKeyDefaultApiarioId = 'voice_default_apiario_id';
  static const _prefKeyDefaultApiarioNome = 'voice_default_apiario_nome';

  AppStrings get _s =>
      Provider.of<LanguageService>(context, listen: false).strings;

  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _apiari = [];
  int? _selectedId;
  String? _selectedNome;

  @override
  void initState() {
    super.initState();
    _loadApiari();
  }

  /// Returns true if the current user can edit [apiario]:
  /// owner, or group member with role admin/editor.
  bool _canEdit(dynamic apiario, int currentUserId, List<dynamic> gruppi) {
    if (apiario['proprietario'] == currentUserId) return true;
    if (apiario['condiviso_con_gruppo'] != true || apiario['gruppo'] == null) return false;

    final apiarioGruppoId = apiario['gruppo'];
    for (final g in gruppi) {
      final gId = g['id'] is String ? int.tryParse(g['id']) : g['id'];
      if (gId != apiarioGruppoId) continue;

      final creatoreId = g['creatore'] is Map
          ? g['creatore']['id']
          : (g['creatore'] is String
              ? int.tryParse(g['creatore'].toString())
              : g['creatore']);
      if (creatoreId == currentUserId) return true;

      final membri = g['membri'];
      if (membri is List) {
        for (final m in membri) {
          final utenteId = m['utente'] is String
              ? int.tryParse(m['utente'].toString())
              : m['utente'];
          if (utenteId == currentUserId) {
            final ruolo = m['ruolo'] as String?;
            return ruolo == 'admin' || ruolo == 'editor';
          }
        }
      }
      return false;
    }
    return false;
  }

  Future<void> _loadApiari() async {
    final currentUserId =
        Provider.of<AuthService>(context, listen: false).currentUser?.id;
    final allApiari = await _storage.getStoredData('apiari');
    final gruppi = await _storage.getStoredData('gruppi');
    if (!mounted) return;

    List<Map<String, dynamic>> filtered;
    if (currentUserId != null) {
      filtered = allApiari
          .cast<Map<String, dynamic>>()
          .where((a) => _canEdit(a, currentUserId, gruppi))
          .toList();
    } else {
      filtered = allApiari.cast<Map<String, dynamic>>();
    }

    setState(() {
      _apiari = filtered;
    });

    // Auto-select the saved default if available and still editable
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getInt(_prefKeyDefaultApiarioId);
    final defaultNome = prefs.getString(_prefKeyDefaultApiarioNome);
    if (defaultId != null && defaultNome != null && mounted) {
      final exists = _apiari.any((a) => a['id'] == defaultId);
      if (exists) {
        setState(() {
          _selectedId = defaultId;
          _selectedNome = defaultNome;
        });
        widget.onApiarioSelected(defaultId, defaultNome);
      }
    }
  }

  Future<void> _saveAsDefault(int id, String nome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyDefaultApiarioId, id);
    await prefs.setString(_prefKeyDefaultApiarioNome, nome);
  }

  Future<void> _clearDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyDefaultApiarioId);
    await prefs.remove(_prefKeyDefaultApiarioNome);
  }

  Future<bool> _isDefault(int id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyDefaultApiarioId) == id;
  }

  void _showApiarioSheet() {
    final s = _s;
    if (_apiari.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.voiceContextNoApiari)),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                s.voiceContextSheetTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: ThemeConstants.primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                s.voiceContextSheetHint,
                style: TextStyle(
                  fontSize: 12,
                  color: ThemeConstants.textSecondaryColor,
                ),
              ),
            ),
            const Divider(),
            ..._apiari.map((a) {
              final id = a['id'] as int?;
              final nome = a['nome'] as String? ?? 'Apiario $id';
              final selected = id == _selectedId;
              return FutureBuilder<bool>(
                future: id != null ? _isDefault(id) : Future.value(false),
                builder: (_, snap) {
                  final isDefault = snap.data ?? false;
                  return ListTile(
                    leading: Icon(
                      Icons.hive,
                      color: selected
                          ? ThemeConstants.primaryColor
                          : ThemeConstants.textSecondaryColor,
                    ),
                    title: Text(nome),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pin icon to set/unset default
                        IconButton(
                          icon: Icon(
                            isDefault ? Icons.push_pin : Icons.push_pin_outlined,
                            color: isDefault
                                ? ThemeConstants.primaryColor
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                          tooltip: isDefault
                              ? s.voiceContextRemoveDefault
                              : s.voiceContextSetDefault,
                          onPressed: id == null
                              ? null
                              : () async {
                                  if (isDefault) {
                                    await _clearDefault();
                                  } else {
                                    await _saveAsDefault(id, nome);
                                  }
                                  setSheetState(() {}); // refresh sheet
                                  if (mounted) setState(() {}); // refresh banner
                                },
                        ),
                        if (selected)
                          Icon(Icons.check, color: ThemeConstants.primaryColor),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      if (id != null) {
                        setState(() {
                          _selectedId = id;
                          _selectedNome = nome;
                        });
                        widget.onApiarioSelected(id, nome);
                      }
                    },
                  );
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedId != null;
    // Rebuild on language change so localized text refreshes live.
    context.watch<LanguageService>();
    final s = _s;

    return GestureDetector(
      onTap: _showApiarioSheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: hasSelection
              ? ThemeConstants.primaryColor.withOpacity(0.08)
              : Colors.grey.shade100,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.hive,
              size: 20,
              color: hasSelection
                  ? ThemeConstants.primaryColor
                  : ThemeConstants.textSecondaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasSelection
                    ? s.voiceContextSelected(_selectedNome ?? '')
                    : s.voiceContextSelect,
                style: TextStyle(
                  color: hasSelection
                      ? ThemeConstants.primaryColor
                      : ThemeConstants.textSecondaryColor,
                  fontWeight:
                      hasSelection ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            // Pin indicator when this apiario is the default
            if (hasSelection)
              FutureBuilder<bool>(
                future: _isDefault(_selectedId!),
                builder: (_, snap) => snap.data == true
                    ? Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.push_pin,
                            size: 14, color: ThemeConstants.primaryColor),
                      )
                    : const SizedBox.shrink(),
              ),
            if (!widget.isOnline)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  s.voiceContextOffline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: ThemeConstants.textSecondaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
