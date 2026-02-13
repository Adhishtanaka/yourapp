import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark IDE color palette — VSCode-inspired neutral grays + navy blue accent
class AppColors {
  // Core backgrounds
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF252525);
  static const Color surfaceVariant = Color(0xFF2D2D2D);
  static const Color elevated = Color(0xFF333333);

  // Navy / Accent
  static const Color navy = Color(0xFF1A2744);
  static const Color navyLight = Color(0xFF1E3A5F);
  static const Color navyDark = Color(0xFF0F172A);
  static const Color accentBlue = Color.fromARGB(255, 5, 193, 193);

  // Text
  static const Color textPrimary = Color(0xFFD6D6D6);
  static const Color textSecondary = Color(0xFF868686);
  static const Color textMuted = Color(0xFF6C6C6C);
  static const Color textOnDark = Color(0xFFF0F0F0);

  // Border
  static const Color border = Color(0xFF404040);
  static const Color borderDark = Color(0xFF333333);

  // Status
  static const Color error = Color(0xFFF14C4C);
  static const Color errorLight = Color(0xFF5A1D1D);
  static const Color success = Color(0xFF4EC9B0);
  static const Color successLight = Color(0xFF1C3D35);

  // Compat aliases
  static const Color slate = Color(0xFF3C3C3C);
  static const Color slateLight = Color(0xFF4A4A4A);
  static const Color slateMuted = Color(0xFF6C6C6C);
}

/// App text styles — Montserrat for UI, Fira Code for code
class AppTextStyles {
  static TextStyle h1 = GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle h2 = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  static TextStyle h3 = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle body = GoogleFonts.montserrat(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  static TextStyle label = GoogleFonts.montserrat(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static TextStyle button = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle caption = GoogleFonts.montserrat(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // Monospace styles for code/spec
  static TextStyle mono = GoogleFonts.firaCode(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle monoSmall = GoogleFonts.firaCode(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}

/// App theme configuration — dark IDE theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        onPrimary: Colors.white,
        secondary: AppColors.textSecondary,
        onSecondary: AppColors.textPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.border,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textSecondary,
          size: 20,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minLeadingWidth: 20,
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
      ),

      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 20,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBlue,
        linearTrackColor: AppColors.border,
        circularTrackColor: AppColors.border,
      ),
    );
  }
}

/// Custom widget styles
class AppWidgetStyles {
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.accentBlue,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.surfaceVariant,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  static ButtonStyle ghostButton = TextButton.styleFrom(
    foregroundColor: AppColors.textSecondary,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  static BoxDecoration inputContainer = BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: AppColors.border, width: 1),
  );

  static BoxDecoration cardContainer = BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: AppColors.border, width: 1),
  );

  static BoxDecoration elevatedCard = BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: AppColors.border, width: 1),
  );
}
