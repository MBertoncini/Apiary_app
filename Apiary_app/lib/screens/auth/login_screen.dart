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
  String _errorMessage = '';
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _errorMessage = '';
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      
      if (success) {
        Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
      } else {
        setState(() {
          _errorMessage = 'Username o password non validi. Riprova.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Si è verificato un errore. Riprova più tardi.';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthService>(context).isLoading;
    
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
                    'Accedi per gestire i tuoi apiari',
                    style: TextStyle(
                      fontSize: 16,
                      color: ThemeConstants.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  
                  // Messaggio di errore
                  if (_errorMessage.isNotEmpty)
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
                        _errorMessage,
                        style: TextStyle(color: ThemeConstants.errorColor),
                      ),
                    ),
                  
                  // Username
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Inserisci il tuo username',
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
                      hintText: 'Inserisci la tua password',
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
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
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
                              'ACCEDI',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Link registrazione
                  TextButton(
                    onPressed: isLoading ? null : () {
                      Navigator.of(context).pushNamed(AppConstants.registerRoute);
                    },
                    child: Text('Non hai un account? Registrati'),
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