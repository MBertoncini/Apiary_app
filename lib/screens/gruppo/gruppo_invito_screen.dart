import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../models/gruppo.dart';
import '../../services/gruppo_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../l10n/app_strings.dart';
import '../../utils/validators.dart';

class GruppoInvitoScreen extends StatefulWidget {
  final int gruppoId;

  GruppoInvitoScreen({required this.gruppoId});

  @override
  _GruppoInvitoScreenState createState() => _GruppoInvitoScreenState();
}

class _GruppoInvitoScreenState extends State<GruppoInvitoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late GruppoService _gruppoService;
  Gruppo? _gruppo;

  final TextEditingController _emailController = TextEditingController();
  String _ruoloSelezionato = 'viewer';

  AppStrings get _s => Provider.of<LanguageService>(context, listen: false).strings;

  @override
  void initState() {
    super.initState();
    final apiService = Provider.of<ApiService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    _gruppoService = GruppoService(apiService, storageService);
    _loadGruppo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadGruppo() async {
    setState(() { _isLoading = true; });

    try {
      _gruppo = await _gruppoService.getGruppoDetail(widget.gruppoId);
      setState(() { _isLoading = false; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.gruppiErrLoading),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _inviaInvito() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() { _isLoading = true; });

    try {
      final email = _emailController.text.trim();
      await _gruppoService.invitaUtente(widget.gruppoId, email, _ruoloSelezionato);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.gruppoInvitoSentOk),
          backgroundColor: ThemeConstants.successColor,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.msgErrorGeneric(e.toString())),
          backgroundColor: ThemeConstants.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Widget _buildRuoloSelector(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.gruppoInvitoLblRuolo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: Text(s.gruppoInvitoRuoloAdmin),
          subtitle: Text(s.gruppoInvitoRuoloAdminDesc),
          value: 'admin',
          groupValue: _ruoloSelezionato,
          onChanged: (value) => setState(() { _ruoloSelezionato = value!; }),
          activeColor: ThemeConstants.primaryColor,
        ),
        RadioListTile<String>(
          title: Text(s.gruppoInvitoRuoloEditor),
          subtitle: Text(s.gruppoInvitoRuoloEditorDesc),
          value: 'editor',
          groupValue: _ruoloSelezionato,
          onChanged: (value) => setState(() { _ruoloSelezionato = value!; }),
          activeColor: ThemeConstants.primaryColor,
        ),
        RadioListTile<String>(
          title: Text(s.gruppoInvitoRuoloViewer),
          subtitle: Text(s.gruppoInvitoRuoloViewerDesc),
          value: 'viewer',
          groupValue: _ruoloSelezionato,
          onChanged: (value) => setState(() { _ruoloSelezionato = value!; }),
          activeColor: ThemeConstants.primaryColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<LanguageService>(context);
    final s = _s;
    return Scaffold(
      appBar: AppBar(title: Text(s.gruppoInvitoTitle)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _gruppo == null
              ? Center(child: Text(s.gruppoInvitoNotFound))
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
                              Text(s.gruppoInvitoHeader(_gruppo!.nome),
                                  style: ThemeConstants.subheadingStyle),
                              const SizedBox(height: 8),
                              Text(s.gruppoInvitoSubtitle,
                                  style: TextStyle(color: ThemeConstants.textSecondaryColor)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: s.gruppoInvitoLblEmail,
                          hintText: s.gruppoInvitoHintEmail,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: Validators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildRuoloSelector(s),
                        ),
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _inviaInvito,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(s.gruppoInvitoBtnSend, style: TextStyle(fontSize: 16)),
                        ),
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 0)),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        s.gruppoInvitoInfo,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ThemeConstants.textSecondaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
    );
  }
}
