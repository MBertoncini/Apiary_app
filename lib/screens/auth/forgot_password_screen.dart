import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/theme_constants.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.forgotPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _emailSent = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password dimenticata'),
        backgroundColor: ThemeConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _emailSent ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ThemeConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_reset,
                size: 48,
                color: ThemeConstants.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reimposta la password',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ThemeConstants.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Inserisci l\'indirizzo email associato al tuo account. Ti invieremo un link per reimpostare la password.',
            style: TextStyle(
              fontSize: 14,
              color: ThemeConstants.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ThemeConstants.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ThemeConstants.errorColor.withOpacity(0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: ThemeConstants.errorColor),
              ),
            ),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Inserisci la tua email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Inserisci la tua email';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value.trim())) {
                return 'Inserisci un indirizzo email valido';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
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
                  : const Text('INVIA LINK', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Torna al login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 48, color: Colors.green),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Email inviata!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Abbiamo inviato le istruzioni per reimpostare la password a:\n${_emailController.text.trim()}\n\nControlla anche la cartella spam.',
          style: TextStyle(fontSize: 14, color: ThemeConstants.textSecondaryColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('TORNA AL LOGIN', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _errorMessage = null;
            });
          },
          child: const Text('Non ho ricevuto l\'email — riprova'),
        ),
      ],
    );
  }
}
