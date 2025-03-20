import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _showDemoLogin = false;
  bool _serverUnavailable = false;
  int _loginAttempts = 0;
  
  @override
  void initState() {
    super.initState();
    _checkServerAvailability();
  }
  
  // Verifica disponibilità del server
  Future<void> _checkServerAvailability() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.refreshUserProfile();
    } catch (e) {
      setState(() {
        _serverUnavailable = true;
        _showDemoLogin = true;
      });
    }
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Nasconde la tastiera
    FocusScope.of(context).unfocus();
    
    setState(() {
      _errorMessage = null;
    });
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      
      bool success;
      if (_showDemoLogin) {
        // Modalità demo (offline)
        success = await auth.demoLogin(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Login normale
        success = await auth.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
      }
      
      if (success) {
        // Reset form
        _usernameController.clear();
        _passwordController.clear();
        
        // Navigate to dashboard
        Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
      }
    } catch (e) {
      _loginAttempts++;
      
      String message;
      if (e is Exception) {
        // Estrai il messaggio dall'eccezione
        message = e.toString().replaceAll('Exception: ', '');
      } else {
        message = 'Si è verificato un errore durante il login. Riprova più tardi.';
      }
      
      setState(() {
        _errorMessage = message;
        
        // Dopo 2 tentativi falliti, mostra l'opzione demo
        if (_loginAttempts >= 2 && !_showDemoLogin) {
          _showDemoLogin = true;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Login fallito'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isLoading = auth.isLoading;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo app
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: ThemeConstants.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.hive,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  
                  Text(
                    _showDemoLogin
                        ? 'Accedi in modalità demo o inserisci le tue credenziali'
                        : 'Accedi per gestire i tuoi apiari',
                    style: TextStyle(
                      fontSize: 16,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (_serverUnavailable) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Server non disponibile. Funzionalità limitate in modalità offline.',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 20),
                  
                  // Messaggio di errore
                  if (_errorMessage != null)
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: ThemeConstants.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ThemeConstants.errorColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: ThemeConstants.errorColor),
                      ),
                    ),
                  
                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: _showDemoLogin 
                          ? 'Per la modalità demo, usa "demo"' 
                          : 'Inserisci il tuo username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci il tuo username';
                      }
                      return null;
                    },
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),
                  
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: _showDemoLogin 
                          ? 'Per la modalità demo, usa "demo"' 
                          : 'Inserisci la tua password',
                      prefixIcon: Icon(Icons.lock),
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
                  SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: isLoading ? null : _login,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _showDemoLogin ? 'ACCEDI / DEMO' : 'ACCEDI',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  
                  if (_showDemoLogin) ...[
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Modalità demo disponibile! Usa "demo" come username e password',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  
                  SizedBox(height: 16),
                  
                  // Link registrazione
                  TextButton(
                    onPressed: isLoading || _serverUnavailable ? null : () {
                      Navigator.of(context).pushNamed(AppConstants.registerRoute);
                    },
                    child: Text(_serverUnavailable 
                        ? 'Registrazione non disponibile in modalità offline'
                        : 'Non hai un account? Registrati'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}