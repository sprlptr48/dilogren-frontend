import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6C63FF); // Modern Indigo
  static const Color secondary = Color(0xFF2A2D3E); // Dark Slate
  static const Color tertiary = Color(0xFFFF6584); // Soft Pink/Red
  static const Color accent = Color(0xFF00D2D3); // Cyan
  
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  
  static const Color success = Color(0xFF00C851);
  static const Color warning = Color(0xFFFFBB33);
  static const Color error = Color(0xFFFF4444);

  // Chat Specific
  static const Color userBubble = primary;
  static const Color aiBubble = surface;
  static const Color inputBackground = Color(0xFFF8F9FE);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Error Types
  static const Color errorGrammar = Color(0xFF42A5F5); // Blue 400
  static const Color errorSpelling = Color(0xFFEF5350); // Red 400
  static const Color errorVocabulary = Color(0xFF66BB6A); // Green 400
  static const Color errorPunctuation = Color(0xFFAB47BC); // Purple 400
  static const Color errorSyntax = Color(0xFFFFA726); // Orange 400
  static const Color errorDefault = Color(0xFFBDBDBD); // Grey 400

  // Chat Screen AppBar Styles (for BaseChatScreen only)
  static const TextStyle chatTitleStyle = TextStyle(
    fontSize: 16,
    color: secondary,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle chatSubtitleStyle = TextStyle(
    fontSize: 12,
    color: Color(0xFF757575), // Grey[600]
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        tertiary: tertiary,
        surface: surface,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: secondary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: secondary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}