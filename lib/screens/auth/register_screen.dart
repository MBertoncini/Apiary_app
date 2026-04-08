import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../constants/theme_constants.dart';
import '../../services/language_service.dart';
import '../privacy_policy_screen.dart';

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
  bool _privacyAccepted = false;
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

    final s = Provider.of<LanguageService>(context, listen: false).strings;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = s.registerErrPasswordMismatch;
      });
      return;
    }

    if (!_privacyAccepted) {
      setState(() {
        _errorMessage = s.registerErrPrivacyRequired;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/v1/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'password1': _passwordController.text,
          'password2': _confirmPasswordController.text,
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.registerSuccessMsg),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
      } else {
        String errorMsg = s.registerErrGeneric;
        if (data is Map) {
          if (data.containsKey('username')) {
            final v = data['username'];
            errorMsg = v is List ? v[0] : v.toString();
          } else if (data.containsKey('email')) {
            final v = data['email'];
            errorMsg = v is List ? v[0] : v.toString();
          } else if (data.containsKey('password1')) {
            final v = data['password1'];
            errorMsg = v is List ? v[0] : v.toString();
          } else if (data.containsKey('non_field_errors')) {
            final v = data['non_field_errors'];
            errorMsg = v is List ? v[0] : v.toString();
          } else if (data.containsKey('detail')) {
            errorMsg = data['detail'].toString();
          }
        }

        setState(() {
          _errorMessage = errorMsg;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = s.registerErrNetwork;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageService>(context).strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.registerTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.registerCreateAccount,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Messaggio di errore
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      margin: const EdgeInsets.only(bottom: 16),
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
                      labelText: s.registerFieldUsername,
                      hintText: s.registerHintUsername,
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.registerValidateUsername;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: s.registerFieldEmail,
                      hintText: s.registerHintEmail,
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return s.registerValidateEmail;
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return s.registerValidateEmailFormat;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: s.registerFieldPassword,
                      hintText: s.registerHintPassword,
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
                        return s.registerValidatePassword;
                      }
                      if (value.length < 8) {
                        return s.registerValidatePasswordLength;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Conferma Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: s.registerFieldConfirmPassword,
                      hintText: s.registerHintConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
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
                        return s.registerValidateConfirmPassword;
                      }
                      if (value != _passwordController.text) {
                        return s.registerValidatePasswordMatch;
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                    onFieldSubmitted: (_) => _register(),
                  ),
                  const SizedBox(height: 16),

                  // Privacy policy checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _privacyAccepted,
                        onChanged: _isLoading
                            ? null
                            : (value) => setState(() => _privacyAccepted = value ?? false),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => setState(() => _privacyAccepted = !_privacyAccepted),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(s.registerPrivacyText, style: const TextStyle(fontSize: 14)),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const PrivacyPolicyScreen()),
                                ),
                                child: Text(
                                  s.registerPrivacyLink,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ThemeConstants.primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pulsante registrazione
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              s.registerBtnRegister,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link login
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
                          },
                    child: Text(s.registerBtnLogin),
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