/// constants/theme_constants.dart - Tema dell'app in stile diario
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConstants {
  // Colori principali ispirati a carta e miele
  static const Color primaryColor = Color(0xFFD3A121);    // Colore miele
  static const Color secondaryColor = Color(0xFF8B5E00);  // Marrone miele scuro
  static const Color backgroundColor = Color(0xFFF8F5E6); // Beige carta
  
  // Altri colori
  static const Color textPrimaryColor = Color(0xFF3A2E21);  // Marrone scuro per testo
  static const Color textSecondaryColor = Color(0xFF6D5D4B);  // Marrone medio
  static const Color dividerColor = Color(0xFFD0C8B0);  // Beige più scuro per divisori
  static const Color errorColor = Color(0xFFAD3B23);  // Rosso ruggine
  static const Color successColor = Color(0xFF688148);  // Verde oliva
  static const Color cardColor = Color(0xFFFFFDF5);  // Carta chiara
  
  // Ombre e texture
  static const BoxShadow paperShadow = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 6.0,
    spreadRadius: 0.5,
    offset: Offset(2, 2),
  );
  
  // Bordi stile carta
  static final BorderRadius paperRadius = BorderRadius.circular(4);
  static final Border paperBorder = Border.all(
    color: Color(0xFFE5DDC8),
    width: 1.0,
  );
  
  // Stili di testo con font "scritti a mano"
  static TextStyle get headingStyle => GoogleFonts.caveat(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    height: 1.1,
  );
  
  static TextStyle get subheadingStyle => GoogleFonts.caveat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
    height: 1.1,
  );
  
  static TextStyle get bodyStyle => GoogleFonts.quicksand(
    fontSize: 16,
    color: textPrimaryColor,
  );

  static TextStyle get handwrittenNotes => GoogleFonts.caveat(
    fontSize: 18,
    color: textPrimaryColor,
    height: 1.3,
  );
  
  // Metodo factory per generare il tema completo
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      fontFamily: 'Quicksand',
      
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
        titleTextStyle: GoogleFonts.caveat(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(88, 48),
          padding: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: paperRadius,
            side: BorderSide(color: secondaryColor.withOpacity(0.3)),
          ),
          elevation: 2,
          shadowColor: Colors.black38,
          textStyle: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: paperRadius,
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: paperRadius,
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: paperRadius,
          borderSide: BorderSide(color: primaryColor),
        ),
        hintStyle: GoogleFonts.quicksand(
          color: textSecondaryColor.withOpacity(0.7),
        ),
      ),
      
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: paperRadius),
        shadowColor: Colors.black45,
        color: cardColor,
        clipBehavior: Clip.antiAlias,
      ),
      
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Personalizzazione della pagina
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      // Decoration di default per contenitori
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 24,
      ),
    );
  }
  
  // Stili per i widget carta
  static BoxDecoration get paperDecoration => BoxDecoration(
    color: cardColor,
    borderRadius: paperRadius,
    boxShadow: [paperShadow],
    border: paperBorder,
  );
  
  // Texture di sfondo (se desideri aggiungere una texture sottile alla carta)
  static DecorationImage get paperBackgroundTexture => DecorationImage(
    image: AssetImage('assets/images/backgrounds/paper_texture.png'),
    fit: BoxFit.cover,
    opacity: 0.08,
  );
}