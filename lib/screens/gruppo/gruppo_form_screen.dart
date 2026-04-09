import 'package:flutter/material.dart';
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
import '../../utils/validators.dart';

class GruppoFormScreen extends StatefulWidget {
  final Gruppo? gruppo;

  GruppoFormScreen({this.gruppo});

  @override
  _GruppoFormScreenState createState() => _GruppoFormScreenState();
}

class _GruppoFormScreenState extends State<GruppoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late GruppoService _gruppoService;

  late TextEditingController _nomeController;
  late TextEditingController _descrizioneController;

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    _gruppoService = GruppoService(apiService, storageService);

    _nomeController = TextEditingController(text: widget.gruppo?.nome ?? '');
    _descrizioneController = TextEditingController(text: widget.gruppo?.descrizione ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _saveGruppo() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() { _isLoading = true; });

    final s = _s;
    try {
      final nome = _nomeController.text.trim();
      final descrizione = _descrizioneController.text.trim();

      if (widget.gruppo == null) {
        await _gruppoService.createGruppo(nome, descrizione);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.gruppoFormCreatedOk),
              backgroundColor: ThemeConstants.successColor),
        );
      } else {
        await _gruppoService.updateGruppo(widget.gruppo!.id, nome, descrizione);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.gruppoFormUpdatedOk),
              backgroundColor: ThemeConstants.successColor),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.msgErrorGeneric(e.toString())),
            backgroundColor: ThemeConstants.errorColor),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gruppo == null ? s.gruppoFormTitleNew : s.gruppoFormTitleEdit),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.gruppoFormSectionInfo, style: ThemeConstants.subheadingStyle),
                          const SizedBox(height: 8),
                          Text(
                            widget.gruppo == null ? s.gruppoFormSubtitleNew : s.gruppoFormSubtitleEdit,
                            style: TextStyle(color: ThemeConstants.textSecondaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: s.gruppoFormLblNome,
                      hintText: s.gruppoFormHintNome,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                    validator: Validators.required,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descrizioneController,
                    decoration: InputDecoration(
                      labelText: s.attrezzaturaDetailLblDescrizione,
                      hintText: s.gruppoFormHintDescrizione,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveGruppo,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        widget.gruppo == null ? s.gruppoFormBtnCrea : s.gruppoFormBtnSalva,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 0)),
                  ),
                ],
              ),
            ),
    );
  }
}
