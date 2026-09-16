import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extracted directly from Figma (Home, Sign In, Crag Detail frames).
class AppColors {
  AppColors._();

  // --- Backgrounds & Surfaces ---
  /// Global scaffold dark background (#131313)
  static const Color background = Color(0xFF131313);

  /// Default card & route item background (#1C1B1B)
  static const Color surface = Color(0xFF1C1B1B);

  /// Elevated card / highlighted surface such as Crag cards (#353534)
  static const Color surfaceElevated = Color(0xFF353534);

  /// Controls, inputs, and icon button backgrounds (#2A2A2A)
  static const Color surfaceInput = Color(0xFF2A2A2A);

  // --- Primary Brand & Accents (Warm Terracotta & Sand) ---
  /// Main climbing brand terracotta orange (#C97E56)
  static const Color primary = Color(0xFFC97E56);

  /// Primary variant tone (#C87D55)
  static const Color primaryVariant = Color(0xFFC87D55);

  /// Light peach accent for ratings, highlights, and tags (#FFB691)
  static const Color primaryLight = Color(0xFFFFB691);

  /// Soft peach container tint (#FFDBCB)
  static const Color primaryContainer = Color(0xFFFFDBCB);

  /// Deep espresso accent for text on light badges (#4A1C00)
  static const Color primaryDark = Color(0xFF4A1C00);

  /// Deep brown tone for contrast text (#542101)
  static const Color primaryDarkDeep = Color(0xFF542101);

  // --- Text & Foreground ---
  /// High-emphasis headline text (#E5E2E1)
  static const Color textPrimary = Color(0xFFE5E2E1);

  /// Warm muted sand text for subtitles, placeholders, and metadata (#D8C2B8)
  static const Color textSecondary = Color(0xFFD8C2B8);

  /// Secondary muted grey text (#A8A29E)
  static const Color textMuted = Color(0xFFA8A29E);

  /// Pure white text (#FFFFFF)
  static const Color textLight = Color(0xFFFFFFFF);

  /// Dark text for primary filled buttons (#111414)
  static const Color onPrimary = Color(0xFF111414);

  // --- Borders & Outlines ---
  /// Standard subtle warm stone border for cards and inputs (#53433C)
  static const Color border = Color(0xFF53433C);

  /// Secondary subtle divider border (#44403C)
  static const Color borderSubtle = Color(0xFF44403C);

  /// Darker border tone (#292524)
  static const Color borderDark = Color(0xFF292524);

  // --- Alert & Status ---
  /// Hazard alert container background (#93000A)
  static const Color hazardContainer = Color(0xFF93000A);

  /// Hazard alert text and icon tint (#FFB4AB)
  static const Color hazardText = Color(0xFFFFB4AB);

  /// Warning accent (#F59E0B)
  static const Color warning = Color(0xFFF59E0B);
}

/// Global border radiuses identified across Figma frames.
class AppRadius {
  AppRadius._();

  /// 4.0 - Chips, grade badges, small tags
  static const double xs = 4.0;

  /// 8.0 - Inputs, route list items, standard action buttons, hazard pill
  static const double sm = 8.0;

  /// 12.0 - Featured Crag cards, bottom sheets
  static const double md = 12.0;

  /// 16.0 - Dialogs, larger containers
  static const double lg = 16.0;

  /// 9999.0 - Pill / Stadium buttons ("SUBMIT NEW ROUTE", "REPORT HAZARD")
  static const double pill = 9999.0;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));
}

/// Typography tokens combining Space Grotesk (headers) and JetBrains Mono (technical body/data).
class AppTextStyles {
  AppTextStyles._();

  // --- Space Grotesk (Headings & Display) ---
  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryContainer,
    letterSpacing: -2.4,
    height: 52.8 / 48,
  );

  static TextStyle headlineLarge = GoogleFonts.spaceGrotesk(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.8,
    height: 38.4 / 32,
  );

  static TextStyle headlineMedium = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 28.8 / 24,
  );

  static TextStyle headlineSmall = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 28.0 / 22,
  );

  static TextStyle titleLarge = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textLight,
    height: 24.0 / 18,
  );

  static TextStyle titleMedium = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    height: 24.0 / 16,
  );

  static TextStyle titleSmall = GoogleFonts.spaceGrotesk(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 22.5 / 15,
  );

  // --- JetBrains Mono (Body, Metadata, Controls) ---
  static TextStyle bodyLarge = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 24.0 / 16,
  );

  static TextStyle bodyMedium = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 20.0 / 14,
    letterSpacing: 0.7,
  );

  static TextStyle bodySmall = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 16.0 / 12,
    letterSpacing: 0.6,
  );

  static TextStyle labelLarge = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 0.7,
    height: 20.0 / 14,
  );

  static TextStyle labelMedium = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.6,
    height: 16.0 / 12,
  );

  static TextStyle labelSmall = GoogleFonts.jetBrainsMono(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryLight,
    height: 16.5 / 11,
  );

  static TextStyle caption = GoogleFonts.jetBrainsMono(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 15.0 / 10,
  );

  /// Climbing grade display style (e.g., '6b+', '7a')
  static TextStyle grade = GoogleFonts.spaceGrotesk(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 28.0 / 22,
  );

  /// Hazard alert text style
  static TextStyle hazardAlert = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.hazardText,
    letterSpacing: -0.3,
    height: 16.0 / 12,
  );
}

/// Material 3 ThemeData unified with Figma tokens for ClimbApp.
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
      labelMedium: AppTextStyles.labelMedium,
      labelSmall: AppTextStyles.labelSmall,
    );

    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.primaryDark,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceElevated,
      error: AppColors.hazardContainer,
      onError: AppColors.hazardText,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderSm,
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          textStyle: AppTextStyles.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderSm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.0),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.textPrimary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderSm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceInput,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.hazardContainer, width: 1.0),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceInput,
        selectedColor: AppColors.primaryLight,
        labelStyle: AppTextStyles.bodySmall,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderXs,
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
