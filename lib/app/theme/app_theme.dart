import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semua warna Julpiypay dalam satu tempat. Dipisah light/dark supaya
/// dark mode benar-benar dirancang, bukan sekadar dibalik.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF167C5A);
  static const primaryDark = Color(0xFF0F5C43);
  static const primaryLight = Color(0xFFE8F5EF);

  // Semantic
  static const income = Color(0xFF159570);
  static const expense = Color(0xFFD95757);
  static const warning = Color(0xFFD89A28);
  static const info = Color(0xFF4F7CAC);

  // Light neutrals
  static const lightBackground = Color(0xFFF8FAF9);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightTextPrimary = Color(0xFF17211D);
  static const lightTextSecondary = Color(0xFF68756F);
  static const lightBorder = Color(0xFFE3E9E6);

  // Dark neutrals — bukan sekadar invert, disesuaikan supaya tetap nyaman.
  static const darkBackground = Color(0xFF0E1512);
  static const darkSurface = Color(0xFF161F1B);
  static const darkCard = Color(0xFF1C2622);
  static const darkTextPrimary = Color(0xFFEDF3F0);
  static const darkTextSecondary = Color(0xFF93A19B);
  static const darkBorder = Color(0xFF283330);
  static const darkPrimaryAccent = Color(0xFF35B888);

  // Palet untuk kategori/akun custom color-picker
  static const categoryPalette = <Color>[
    Color(0xFF167C5A),
    Color(0xFFD95757),
    Color(0xFFD89A28),
    Color(0xFF4F7CAC),
    Color(0xFF8A6FD8),
    Color(0xFFDB6FA0),
    Color(0xFF5FAF9A),
    Color(0xFFC77B3E),
    Color(0xFF6B8E4E),
    Color(0xFF4A6FA5),
  ];
}

class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w700, color: primaryText, letterSpacing: -0.5),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w700, color: primaryText),
      headlineSmall: base.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w600, color: primaryText),
      titleLarge: base.titleLarge
          ?.copyWith(fontWeight: FontWeight.w600, color: primaryText),
      titleMedium: base.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, color: primaryText),
      titleSmall: base.titleSmall
          ?.copyWith(fontWeight: FontWeight.w500, color: primaryText),
      bodyLarge: base.bodyLarge?.copyWith(color: primaryText),
      bodyMedium: base.bodyMedium?.copyWith(color: primaryText),
      bodySmall: base.bodySmall?.copyWith(color: secondaryText),
      labelLarge: base.labelLarge
          ?.copyWith(fontWeight: FontWeight.w600, color: primaryText),
      labelMedium: base.labelMedium?.copyWith(color: secondaryText),
      labelSmall: base.labelSmall?.copyWith(color: secondaryText),
    );
  }

  /// Style khusus angka/nominal — sedikit lebih tegas dari body text.
  /// fontFeatures memastikan angka nol tampil polos (bukan dotted/slashed
  /// zero) dan lebar tiap digit konsisten (tabular figures) supaya nominal
  /// uang selalu rapi sejajar.
  static TextStyle amount(Color color, {double size = 20}) => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        fontSize: size,
        color: color,
        letterSpacing: -0.3,
        fontFeatures: const [
          FontFeature.slashedZero(false),
          FontFeature.tabularFigures(),
        ],
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final textTheme =
        AppTextStyles.textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryDark,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.expense,
      ),
      textTheme: textTheme,
      dividerColor: AppColors.lightBorder,
      cardColor: AppColors.lightSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final textTheme =
        AppTextStyles.textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimaryAccent,
        onPrimary: Colors.black,
        secondary: AppColors.primaryLight,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.expense,
      ),
      textTheme: textTheme,
      dividerColor: AppColors.darkBorder,
      cardColor: AppColors.darkCard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.darkPrimaryAccent,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkPrimaryAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.expense),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimaryAccent,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkCard,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: AppColors.darkTextPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
