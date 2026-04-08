import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/language_service.dart';

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

  Future<void> _loginWithGoogle() async {
    setState(() => _errorCode = null);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final success = await auth.loginWithGoogle();
      if (success && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final onboardingCompletato = prefs.getBool('onboarding_completato') ?? false;
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            onboardingCompletato
                ? AppConstants.dashboardRoute
                : AppConstants.onboardingRoute,
          );
        }
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
      setState(() => _errorCode = raw);
    }
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

  String _errorMessage(BuildContext context) {
    final s = Provider.of<LanguageService>(context, listen: false).strings;
    switch (_errorCode) {
      case 'user_not_found':    return s.loginErrUserNotFound;
      case 'wrong_password':    return s.loginErrWrongPassword;
      case 'wrong_credentials': return s.loginErrWrongCredentials;
      case 'google_auth_error': return s.loginErrGoogleAuth;
      case 'google_token_error':return s.loginErrGoogleToken;
      case 'network_error':     return s.loginErrNetwork;
      case 'timeout_error':     return s.loginErrTimeout;
      case 'server_error':      return s.loginErrServer;
      default:                  return _errorCode ?? s.loginErrDefault;
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
    final s = Provider.of<LanguageService>(context).strings;

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
                    s.loginSubtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Box errore contestuale
                  if (_errorCode != null) _buildErrorBox(s),

                  // Username o Email
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: s.loginFieldUsernameLabel,
                      hintText: s.loginFieldUsernameHint,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return s.loginFieldUsernameValidate;
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
                      labelText: s.loginFieldPasswordLabel,
                      hintText: s.loginFieldPasswordHint,
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
                        return s.loginFieldPasswordValidate;
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
                      child: Text(
                        s.loginForgotPassword,
                        style: const TextStyle(fontSize: 13),
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
                          : Text(s.loginBtnAccedi, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider "oppure"
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          s.loginOr,
                          style: TextStyle(
                            color: ThemeConstants.textSecondaryColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bottone Google
                  OutlinedButton(
                    onPressed: isLoading ? null : _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/icons/google_logo.png',
                          height: 20,
                          width: 20,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.g_mobiledata, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          s.loginBtnGoogle,
                          style: const TextStyle(fontSize: 15, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Link registrazione
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppConstants.registerRoute),
                    child: Text(s.loginBtnRegister),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBox(dynamic s) {
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
                  _errorMessage(context),
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
                  child: Text(s.loginHintForgotPassword,
                      style: const TextStyle(fontSize: 13)),
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
                  child: Text(s.loginHintRegister,
                      style: const TextStyle(fontSize: 13)),
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
