import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../screens/disclaimer_screen.dart';
import '../widgets/beehive_illustrations.dart'; // Widget personalizzati per le illustrazioni
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Inizializza le animazioni
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    // Attendi che inizializzi il provider
    await Future.delayed(Duration(milliseconds: 100));

    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<StorageService>(context, listen: false);

    // Attendi il completamento della verifica token
    while (authService.isLoading) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Mostra splash per almeno 3 secondi (più lungo per apprezzare l'animazione)
    await Future.delayed(Duration(seconds: 3));

    // Verifica se l'utente ha già accettato il disclaimer
    final hasAcceptedDisclaimer = await storageService.hasAcceptedDisclaimer();

    if (!hasAcceptedDisclaimer) {
      // Mostra il disclaimer
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DisclaimerScreen(
            isFirstLogin: !authService.isAuthenticated,
          ),
        ),
      );
      return;
    }

    // Procedi con il flusso normale
    if (authService.isAuthenticated) {
      // Utente autenticato, carica dati iniziali
      try {
        final apiService = Provider.of<ApiService>(context, listen: false);

        // Ottieni l'ultimo timestamp di sync
        final lastSync = await storageService.getLastSyncTimestamp();

        // Sincronizza dati
        final syncData = await apiService.syncData(lastSync: lastSync);
        await storageService.saveSyncData(syncData);
      } catch (e) {
        debugPrint('Error during initial sync: $e');
      }

      Navigator.of(context).pushReplacementNamed(AppConstants.dashboardRoute);
    } else {
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Usa un gradiente che imita la carta di un diario
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ThemeConstants.backgroundColor,
              ThemeConstants.backgroundColor.withBlue(
                  ThemeConstants.backgroundColor.blue - 10)
            ],
          ),
          image: ThemeConstants.paperBackgroundTexture,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustrazione personalizzata invece dell'icona standard
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    children: [
                      // Illustrazione di sfondo di un apiario
                      HandDrawnApiary(
                        size: 160,
                        beehiveCount: 5,
                        color: ThemeConstants.primaryColor,
                      ),

                      // Piccole api che volano attorno
                      Positioned(
                        top: 20,
                        left: 30,
                        child: _buildFlyingBee(size: 20, delay: 1500),
                      ),
                      Positioned(
                        top: 40,
                        right: 40,
                        child: _buildFlyingBee(size: 15, delay: 800),
                      ),
                      Positioned(
                        bottom: 50,
                        right: 20,
                        child: _buildFlyingBee(size: 18, delay: 2000),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Titolo in stile scritto a mano
                Text(
                  'Apiary',
                  style: GoogleFonts.caveat(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.primaryColor,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(1, 1),
                        blurRadius: 2,
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sottotitolo
                Text(
                  'Gestisci i tuoi apiari ovunque',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    color: ThemeConstants.textSecondaryColor,
                  ),
                ),

                SizedBox(height: 48),

                // Personalizza l'indicatore di caricamento
                Container(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ThemeConstants.primaryColor),
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Crea un'animazione di ape volante
  Widget _buildFlyingBee({required double size, required int delay}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: -0.5, end: 0.5),
      duration: Duration(milliseconds: 2000 + delay),
      curve: Curves.easeInOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(
            size * math.sin(value * math.pi * 2) * 1.5,
            size * math.cos(value * math.pi * 2) * 0.8,
          ),
          child: child,
        );
      },
      child: CustomPaint(
        size: Size(size, size),
        painter: SimpleBee(),
      ),
    );
  }
}

// Disegno semplice di un'ape
class SimpleBee extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ThemeConstants.secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1;

    final fillPaint = Paint()
      ..color = ThemeConstants.primaryColor
      ..style = PaintingStyle.fill;

    // Corpo
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.4,
      fillPaint,
    );

    // Strisce
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.4),
      paint,
    );

    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.6),
      Offset(size.width * 0.6, size.height * 0.6),
      paint,
    );

    // Ali
    final wingPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.3),
        width: size.width * 0.4,
        height: size.width * 0.2,
      ),
      wingPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.6, size.height * 0.3),
        width: size.width * 0.4,
        height: size.width * 0.2,
      ),
      wingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
