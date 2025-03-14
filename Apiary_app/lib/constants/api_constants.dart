class ApiConstants {
  // Base URL dell'API
  static const String baseUrl = "https://Cible99.pythonanywhere.com";
  static const String apiPrefix = "/api";
  
  // Auth endpoints
  static const String tokenUrl = "$apiPrefix/token/";
  static const String tokenRefreshUrl = "$apiPrefix/token/refresh/";
  
  // Data endpoints
  static const String apiariUrl = "$apiPrefix/apiari/";
  static const String arnieUrl = "$apiPrefix/arnie/";
  static const String controlliUrl = "$apiPrefix/controlli/";
  static const String regineUrl = "$apiPrefix/regine/";
  static const String fioritureUrl = "$apiPrefix/fioriture/";
  static const String trattamentiUrl = "$apiPrefix/trattamenti/";
  static const String tipiTrattamentoUrl = "$apiPrefix/tipi-trattamento/";
  static const String melariUrl = "$apiPrefix/melari/";
  static const String smielatureUrl = "$apiPrefix/smielature/";
  static const String gruppiUrl = "$apiPrefix/gruppi/";
  
  // Sync endpoint
  static const String syncUrl = "$apiPrefix/sync/";
}

/// constants/theme_constants.dart - Tema dell'app
import 'package:flutter/material.dart';

class ThemeConstants {
  // Colori principali
  static const Color primaryColor = Color(0xFF128C7E);    // Verde principale
  static const Color secondaryColor = Color(0xFF34B7F1);  // Azzurro secondario
  static const Color backgroundColor = Color(0xFFF5F5F5); // Grigio chiaro sfondo
  
  // Altri colori
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFBDBDBD);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color cardColor = Colors.white;
  
  // Temi di testo
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textPrimaryColor,
  );
  
  // Metodo factory per generare il tema completo
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: cardColor,
        background: backgroundColor,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(88, 48),
          padding: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}