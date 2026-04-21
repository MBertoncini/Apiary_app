import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/storage_service.dart';
import '../services/language_service.dart';

class DisclaimerScreen extends StatefulWidget {
  final bool isFirstLogin;

  DisclaimerScreen({this.isFirstLogin = true});

  @override
  _DisclaimerScreenState createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _dontShowAgain = false;

  Future<void> _acceptDisclaimer() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    // Salva la preferenza se l'utente ha selezionato "non visualizzare più"
    if (_dontShowAgain) {
      await storageService.saveDisclaimerAccepted(true);
    }
    
    // Naviga alla prossima schermata in base al flusso
    if (widget.isFirstLogin) {
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
    } else {
      Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
    }
  }

  void _rejectDisclaimer() {
    // Chiudi l'app se l'utente rifiuta
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // Logo app
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: ThemeConstants.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.hive,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        s.disclaimerTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ThemeConstants.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Contenuto disclaimer
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          s.disclaimerBody,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Checkbox "non visualizzare più"
                      Row(
                        children: [
                          Checkbox(
                            value: _dontShowAgain,
                            onChanged: (value) {
                              setState(() {
                                _dontShowAgain = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _dontShowAgain = !_dontShowAgain;
                                });
                              },
                              child: Text(
                                s.disclaimerDontShow,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Pulsanti
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _rejectDisclaimer,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        s.disclaimerBtnReject,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptDisclaimer,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        s.disclaimerBtnAccept,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}