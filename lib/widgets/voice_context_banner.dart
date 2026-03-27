// lib/widgets/voice_context_banner.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';
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

  final StorageService _storage = StorageService();
  List<Map<String, dynamic>> _apiari = [];
  int? _selectedId;
  String? _selectedNome;

  @override
  void initState() {
    super.initState();
    _loadApiari();
  }

  Future<void> _loadApiari() async {
    final data = await _storage.getStoredData('apiari');
    if (!mounted) return;
    setState(() {
      _apiari = data.cast<Map<String, dynamic>>();
    });
    // Auto-select the saved default if available
    final prefs = await SharedPreferences.getInstance();
    final defaultId = prefs.getInt(_prefKeyDefaultApiarioId);
    final defaultNome = prefs.getString(_prefKeyDefaultApiarioNome);
    if (defaultId != null && defaultNome != null && mounted) {
      // Verify it still exists in the local list
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
    if (_apiari.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun apiario disponibile')),
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
                'Seleziona apiario',
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
                'Tocca la puntina per impostare un apiario predefinito.',
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
                              ? 'Rimuovi predefinito'
                              : 'Imposta come predefinito',
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
                    ? 'Apiario: $_selectedNome'
                    : 'Seleziona apiario...',
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
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
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
