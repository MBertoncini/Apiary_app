import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorCode;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _errorCode = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        _usernameController.clear();
        _passwordController.clear();

        final prefs = await SharedPreferences.getInstance();
        final onboardingCompletato = prefs.getBool('onboarding_completato') ?? false;
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            onboardingCompletato
                ? AppConstants.dashboardRoute
                : AppConstants.onboardingRoute,
          );
        }

        // Sincronizzazione in background
        () async {
          try {
            final apiService = Provider.of<ApiService>(context, listen: false);
            final storageService = Provider.of<StorageService>(context, listen: false);
            await storageService.clearDataCache();
            final syncData = await apiService.syncData();
            await storageService.saveSyncData(syncData);
          } catch (e) {
            debugPrint('Post-login sync fallita (non bloccante): $e');
          }
        }();
      }
    } catch (e) {
      final raw = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorCode = raw;
      });
    }
  }

  String _errorMessage() {
    switch (_errorCode) {
      case 'user_not_found':
        return 'Username o email non trovati. Non hai ancora un account?';
      case 'wrong_password':
        return 'Password errata.';
      case 'wrong_credentials':
        return 'Credenziali non valide. Controlla username/email e password.';
      case 'network_error':
        return 'Impossibile connettersi al server. Controlla la connessione internet.';
      case 'timeout_error':
        return 'Il server non risponde. Riprova tra qualche istante.';
      case 'server_error':
        return 'Errore interno del server. Riprova più tardi.';
      default:
        return _errorCode ?? 'Si è verificato un errore. Riprova.';
    }
  }

  // Mostra "Hai dimenticato la password?" solo se la password è sbagliata
  bool get _showForgotPasswordHint => _errorCode == 'wrong_password';

  // Mostra "Registrati" solo se l'utente non esiste
  bool get _showRegisterHint => _errorCode == 'user_not_found';

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isLoading = auth.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hive, size: 60, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Accedi per gestire i tuoi apiari',
                    style: TextStyle(
                      fontSize: 16,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Box errore contestuale
                  if (_errorCode != null) _buildErrorBox(),

                  // Username o Email
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username o Email',
                      hintText: 'Inserisci il tuo username o email',
                      prefixIcon: Icon(Icons.person),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci il tuo username o email';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Inserisci la tua password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci la tua password';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 4),

                  // Link dimenticato password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context)
                              .pushNamed(AppConstants.forgotPasswordRoute),
                      child: const Text(
                        'Hai dimenticato la password?',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Bottone login
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('ACCEDI', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link registrazione
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppConstants.registerRoute),
                    child: const Text('Non hai un account? Registrati'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeConstants.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ThemeConstants.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline,
                  color: ThemeConstants.errorColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage(),
                  style: TextStyle(
                      color: ThemeConstants.errorColor, fontSize: 14),
                ),
              ),
            ],
          ),

          // 1° tentativo fallito → suggerisce reset password
          if (_showForgotPasswordHint) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.lock_reset,
                    size: 16, color: ThemeConstants.primaryColor),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppConstants.forgotPasswordRoute),
                  child: const Text('Hai dimenticato la password?',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],

          // 2°+ tentativi → suggerisce registrazione
          if (_showRegisterHint) ...[
            Row(
              children: [
                Icon(Icons.person_add_outlined,
                    size: 16, color: ThemeConstants.primaryColor),
                TextButton(
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushNamed(AppConstants.registerRoute),
                  child: const Text('Non hai un account? Registrati ora',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
