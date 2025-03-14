import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Le password non corrispondono.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/register/'),
        body: {
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password1': _passwordController.text,
          'password2': _confirmPasswordController.text,
        },
      );
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        // Registrazione avvenuta con successo, reindirizza al login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrazione completata. Ora puoi effettuare il login.'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
      } else {
        // Errore di registrazione
        String errorMsg = 'Errore durante la registrazione.';
        if (data.containsKey('username')) {
          errorMsg = data['username'][0];
        } else if (data.containsKey('email')) {
          errorMsg = data['email'][0];
        } else if (data.containsKey('password1')) {
          errorMsg = data['password1'][0];
        } else if (data.containsKey('non_field_errors')) {
          errorMsg = data['non_field_errors'][0];
        }
        
        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di connessione. Riprova più tardi.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrazione'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea un account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primaryColor,
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
                      hintText: 'Inserisci un username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci un username';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Inserisci la tua email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci una email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Inserisci una email valida';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),
                  
                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Inserisci una password',
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
                        return 'Inserisci una password';
                      }
                      if (value.length < 8) {
                        return 'La password deve contenere almeno 8 caratteri';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16),
                  
                  // Conferma Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Conferma Password',
                      hintText: 'Conferma la tua password',
                      prefixIcon: Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Conferma la tua password';
                      }
                      if (value != _passwordController.text) {
                        return 'Le password non corrispondono';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    onFieldSubmitted: (_) => _register(),
                  ),
                  SizedBox(height: 24),
                  
                  // Pulsante registrazione
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'REGISTRATI',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Link login
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
                    },
                    child: Text('Hai già un account? Accedi'),
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