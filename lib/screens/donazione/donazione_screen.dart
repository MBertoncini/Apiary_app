import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_constants.dart';
import '../../constants/theme_constants.dart';
import '../../widgets/drawer_widget.dart';

class DonazioneScreen extends StatefulWidget {
  const DonazioneScreen({Key? key}) : super(key: key);

  @override
  State<DonazioneScreen> createState() => _DonazioneScreenState();
}

class _DonazioneScreenState extends State<DonazioneScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _floatAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _messaggioController = TextEditingController();
  bool _isSubmitting = false;

  static const String _feedbackEmail = 'michele.bertoncini@gmail.com';
  static const String _buyMeCoffeeUrl = 'https://www.buymeacoffee.com/apiary';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    _messaggioController.dispose();
    super.dispose();
  }

  Future<void> _openBuyMeCoffee() async {
    final uri = Uri.parse(_buyMeCoffeeUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossibile aprire il link.')),
        );
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSubmitting = true);

    final nome = _nomeController.text.trim();
    final emailMittente = _emailController.text.trim();
    final messaggio = _messaggioController.text.trim();

    final subject = Uri.encodeComponent('[Apiary Feedback] da $nome');
    final body = Uri.encodeComponent(
      'Nome: $nome\n'
      '${emailMittente.isNotEmpty ? 'Rispondi a: $emailMittente\n' : ''}'
      '\n$messaggio',
    );

    final uri = Uri.parse('mailto:$_feedbackEmail?subject=$subject&body=$body');

    setState(() => _isSubmitting = false);

    if (await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Grazie! Il tuo messaggio è stato preparato.'),
            backgroundColor: ThemeConstants.successColor,
          ),
        );
        _nomeController.clear();
        _emailController.clear();
        _messaggioController.clear();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Nessuna app email trovata. Scrivici a $_feedbackEmail'),
            backgroundColor: ThemeConstants.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offrici un caffè'),
      ),
      drawer: AppDrawer(currentRoute: AppConstants.donazioneRoute),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(),
            const SizedBox(height: 24),
            _buildInfoCards(),
            const SizedBox(height: 24),
            _buildFeedbackForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1810), Color(0xFF5C3317), Color(0xFF8B4513)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatAnimation.value),
                child: child,
              ),
              child: const Text('☕', style: TextStyle(fontSize: 72)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apiario Manager',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Caveat',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Un progetto aperto, fatto da apicoltori per apicoltori.\n'
              'Se ti è utile, offrici un caffè!',
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openBuyMeCoffee,
              icon: const Text('☕', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Offrici un caffè',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    final items = [
      _InfoItem(
        icon: Icons.code,
        color: const Color(0xFF4CAF50),
        title: '100% Open Source',
        description:
            'Il codice è pubblico e accessibile a tutti. Nessuna funzionalità nascosta.',
      ),
      _InfoItem(
        icon: Icons.hive,
        color: const Color(0xFFD3A121),
        title: 'Fatto da apicoltori',
        description:
            'Ogni funzionalità nasce dall\'esperienza diretta sul campo, per chi davvero alleva api.',
      ),
      _InfoItem(
        icon: Icons.cloud,
        color: const Color(0xFF2196F3),
        title: 'Costi infrastruttura',
        description:
            'Server, dominio e archiviazione cloud hanno un costo reale. Il tuo aiuto li copre.',
      ),
      _InfoItem(
        icon: Icons.auto_awesome,
        color: const Color(0xFF9C27B0),
        title: 'Crescita continua',
        description:
            'Django · Flutter · AI/YOLO · Gemini. Investiamo in tecnologia per te.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Each card is ~half the width minus spacing; give it ~20% more height than width.
        final cardWidth = (constraints.maxWidth - 12) / 2;
        final aspectRatio = cardWidth / (cardWidth * 1.2);
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items.map(_buildInfoCard).toList(),
        );
      },
    );
  }

  Widget _buildInfoCard(_InfoItem item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: ThemeConstants.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 11,
                color: ThemeConstants.textPrimaryColor.withValues(alpha: 0.7),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline,
                    color: ThemeConstants.primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Mandaci un messaggio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.textPrimaryColor,
                    fontFamily: 'Caveat',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Segnala un bug, proponi una funzionalità o lasciaci il tuo feedback.',
              style: TextStyle(
                fontSize: 13,
                color: ThemeConstants.textPrimaryColor.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Il nome è obbligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (opzionale, per risponderti)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Email non valida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messaggioController,
                    decoration: const InputDecoration(
                      labelText: 'Messaggio *',
                      prefixIcon: Icon(Icons.message_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 5,
                    maxLength: 2000,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Il messaggio è obbligatorio'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_isSubmitting ? 'Invio...' : 'Invia feedback'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _InfoItem(
      {required this.icon,
      required this.color,
      required this.title,
      required this.description});
}
