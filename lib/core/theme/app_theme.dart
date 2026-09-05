import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // 60% Light Foundation
  static const Color background = Color(0xFFF6F8FC); // Luminous pearl canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure white surfaces
  static const Color surfaceElevated = Color(0xFFF0F4F9); // Light neutral tint
  static const Color surfaceCard = Color(0xFFFFFFFF);

  // 40% Futuristic Tech Sapphire & Royal Blue (refined, modern, NOT pitch black)
  static const Color primaryNavy = Color(0xFF112D55); // Deep Tech Sapphire
  static const Color secondaryNavy = Color(0xFF1A3E78); // Royal Cobalt Blue
  static const Color navySurface = Color(0xFF1E3A68); // Slate Sapphire
  static const Color navyGlass = Color(0xFF142F5B);

  // Vibrant Futuristic Accents
  static const Color primaryColor = Color(0xFF2563EB); // Royal Electric Blue
  static const Color primaryLight = Color(0xFF06B6D4); // Cyber Cyan
  static const Color primaryDark = Color(0xFF1D4ED8); // Deep Royal Blue

  static const Color cyberCyan = Color(0xFF00E5FF);
  static const Color cyberIndigo = Color(0xFF6366F1);
  static const Color cyberViolet = Color(0xFF8B5CF6);
  static const Color cyberBlue = Color(0xFF38BDF8);

  static const Color accentColor = Color(0xFF10B981); // Emerald Glow
  static const Color warningColor = Color(0xFFF59E0B); // Amber Warning
  static const Color errorColor = Color(0xFFEF4444); // Coral Red
  static const Color infoColor = Color(0xFF0284C7); // Sky Azure
  static const Color primaryBlue = Color(0xFF2563EB);

  // Typography Palette
  static const Color textPrimary = Color(0xFF0F172A); // Obsidian slate
  static const Color textSecondary = Color(0xFF64748B); // Cool muted slate
  static const Color textMuted = Color(0xFF94A3B8); // Subtle light slate
  static const Color textOnDark = Color(0xFFF8FAFC); // Crisp white

  // Borders & Glass Accents
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color borderGlass = Color(0x3338BDF8);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF102D5E), Color(0xFF194488), Color(0xFF2563EB)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2B5C), Color(0xFF1A4384), Color(0xFF2563EB)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0284C7), Color(0xFF2563EB), Color(0xFF6366F1)],
  );

  static const LinearGradient cyanIndigoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF6366F1)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient cardGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  // Soft Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: 0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: const Color(0xFF0F1E36).withValues(alpha: 0.25),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.25}) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // Backward compatibility & feature aliases
  static const Color backgroundColor = background;
  static const Color surfaceColor = surface;
  static const Color canvasWhite = background;
  static const Color cardLight = surface;
  static const Color cardBorder = borderColor;
  static const Color navyDeep = Color(0xFF112D55);
  static const Color navyPrimary = Color(0xFF2563EB);
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
        primaryContainer: Color(0xFFDBEAFE),
        onPrimaryContainer: Color(0xFF1E3A8A),
        secondary: primaryNavy,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFF0F4F9),
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
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: borderColor.withValues(alpha: 0.8),
            width: 1,
          ),
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
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
          side: BorderSide(color: borderColor.withValues(alpha: 0.9)),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderColor),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: textSecondary, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
