import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // 60% White / Light Foundation
  static const Color background = Color(0xFFF8FAFC); // Light slate canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards & dialogs
  static const Color surfaceElevated = Color(0xFFF1F5F9); // Light neutral gray
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // 40% Navy & Teal Accents
  static const Color primaryNavy = Color(0xFF0B1F33); // Deep Executive Navy
  static const Color secondaryNavy = Color(0xFF163A59); // Slate Navy
  static const Color primaryColor = Color(0xFF0D9488); // Deep Emerald / Teal
  static const Color primaryLight = Color(0xFF14B8A6); // Vibrant Teal
  static const Color primaryDark = Color(0xFF042F2E);

  static const Color accentColor = Color(0xFF10B981); // Emerald Positive
  static const Color warningColor = Color(0xFFD97706); // Amber Warning
  static const Color errorColor = Color(0xFFDC2626); // Coral Red
  static const Color infoColor = Color(0xFF0284C7); // Sky Blue
  static const Color primaryBlue = Color(0xFF2563EB); // Executive Blue

  // Typography Palette
  static const Color textPrimary = Color(0xFF0F172A); // Dark slate
  static const Color textSecondary = Color(0xFF64748B); // Muted slate
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnDark = Color(
    0xFFF8FAFC,
  ); // Crisp white text on dark cards

  // Borders & Dividers
  static const Color borderColor = Color(0xFFE2E8F0); // Subtle clean border
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF334155);

  // Backward compatibility & feature aliases
  static const Color backgroundColor = background;
  static const Color surfaceColor = surface;
  static const Color canvasWhite = background;
  static const Color cardLight = surface;
  static const Color cardBorder = borderColor;
  static const Color navyDeep = primaryNavy;
  static const Color navyPrimary = primaryNavy;
  static const Color tealAccent = primaryLight;
  static const Color coralRisk = errorColor;
  static const Color amberWarning = warningColor;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFCCFBF1),
        onPrimaryContainer: Color(0xFF042F2E),
        secondary: primaryNavy,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFE2E8F0),
        onSecondaryContainer: primaryNavy,
        surface: surface,
        onSurface: textPrimary,
        error: errorColor,
        onError: Colors.white,
        outline: borderColor,
        outlineVariant: borderLight,
      ),
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: borderColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primaryNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryLight.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryLight);
          }
          return const IconThemeData(color: Color(0xFF94A3B8));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.normal,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          side: const BorderSide(color: Color(0xFFCBD5E1)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(64, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderColor),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(color: borderColor),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: primaryColor.withValues(alpha: 0.15),
        secondarySelectedColor: primaryColor,
        disabledColor: surface,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 13),
        secondaryLabelStyle: const TextStyle(color: primaryColor, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderColor),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 24,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceElevated,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
