// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/route_generator.dart';
import 'utils/navigator_key.dart';
import 'constants/app_constants.dart';
import 'constants/theme_constants.dart';
import 'database/database_helper.dart';
import 'provider_setup.dart';
import 'services/language_service.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';
import 'services/nfc_handler.dart';
import 'services/deep_link_handler.dart';
import 'services/notification_service.dart';
import 'services/notification_navigator.dart';
import 'services/update_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (kDebugMode) {
        debugPrint('======= FLUTTER ERROR =======');
        debugPrint('${details.exception}');
        debugPrint('${details.stack}');
      }
    };

    final dbHelper = DatabaseHelper();
    await dbHelper.database;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Edge-to-edge: il contenuto si estende sotto status bar e nav bar
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));

    runApp(
      MultiProvider(
        providers: providers,
        child: _InitSubscription(
          child: Consumer<LanguageService>(
          builder: (context, languageService, _) => MaterialApp(
            navigatorKey: navigatorKey,
            title: AppConstants.appName,
            theme: ThemeConstants.getTheme(),
            locale: languageService.locale,
            supportedLocales: LanguageService.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            onGenerateRoute: RouteGenerator.generateRoute,
            // SafeArea globale: protegge il basso da gesture bar / tasti nav
            // top: false perché AppBar gestisce già la status bar
            builder: (context, child) => SafeArea(
              top: false,
              child: child!,
            ),
          ),
        ),
        ),
      ),
    );
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('======= UNCAUGHT ERROR =======');
      debugPrint('$error');
      debugPrint('$stack');
    }
  });
}

/// Eagerly initializes [SubscriptionService] once the widget tree is ready.
class _InitSubscription extends StatefulWidget {
  final Widget child;
  const _InitSubscription({required this.child});

  @override
  State<_InitSubscription> createState() => _InitSubscriptionState();
}

class _InitSubscriptionState extends State<_InitSubscription>
    with WidgetsBindingObserver {
  StreamSubscription<String?>? _notifTapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final subService = Provider.of<SubscriptionService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final nfcHandler = Provider.of<NfcHandler>(context, listen: false);
      final deepLinkHandler = Provider.of<DeepLinkHandler>(context, listen: false);

      // Let AuthService call RC login/logout automatically.
      authService.subscriptionService = subService;
      subService.init();
      nfcHandler.init();
      deepLinkHandler.init();

      // Centro notifiche locale: init plugin, canali e listener tap.
      final notif = NotificationService();
      await notif.init();
      await notif.createNotificationChannels();
      _notifTapSub = notif.onNotificationClick.listen(_handleNotificationTap);

      // Play Store In-App Update: se l'utente nega o il flusso fallisce si
      // ritenta al resume (vedi didChangeAppLifecycleState). No-op fuori Android.
      UpdateService.checkForUpdate();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UpdateService.checkForUpdate();
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (payload.startsWith('notifica:')) {
      navigatorKey.currentState?.pushNamed(AppConstants.notificationCenterRoute);
      return;
    }
    final parts = payload.split(':');
    final tipo = parts[0];
    final arg = parts.length > 1 ? int.tryParse(parts[1]) : null;
    switch (tipo) {
      case 'controllo':
        if (arg != null) {
          navigatorKey.currentState?.pushNamed(
            AppConstants.arniaDetailRoute,
            arguments: arg,
          );
        }
        break;
      case 'trattamento':
        navigatorKey.currentState?.pushNamed(AppConstants.trattamentiRoute);
        break;
      case 'smielatura':
        navigatorKey.currentState?.pushNamed(AppConstants.smielaturaListRoute);
        break;
      case 'gruppi':
        navigatorKey.currentState?.pushNamed(AppConstants.gruppiListRoute);
        break;
      default:
        // payload non riconosciuto: prova come linkRoute del dropdown admin.
        NotificationNavigator.navigate(linkRoute: tipo);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifTapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
