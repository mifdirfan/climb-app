import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Streamlined color palette for ClimbMY with #CFFF74 as prime brand color.
/// Reduced color usage: clean monochrome foundation, electric lime brand accents,
/// and semantic alert tones without gradients.
class AppColors {
  AppColors._();

  // --- Primary Brand Accent (#CFFF74 Electric Lime) ---
  /// Prime brand color (#CFFF74)
  static const Color primary = Color(0xFFCFFF74);

  /// High-contrast dark text/icon on primary filled buttons (#11140E)
  static const Color onPrimary = Color(0xFF11140E);

  /// Primary variant tone (#B8F255)
  static const Color primaryVariant = Color(0xFFB8F255);

  /// Light lime tint for highlights and tags (#DCFF9E)
  static const Color primaryLight = Color(0xFFDCFF9E);

  /// Soft lime container tint (#CFFF74)
  static const Color primaryContainer = Color(0xFFCFFF74);

  /// Deep olive accent for text on light badges (#1E2E04)
  static const Color primaryDark = Color(0xFF1E2E04);

  /// Deep dark tone (#11140E)
  static const Color primaryDarkDeep = Color(0xFF11140E);

  // --- Dark Mode Surfaces & Backgrounds ---
  /// Global scaffold dark background (#121212)
  static const Color background = Color(0xFF121212);

  /// Default card & item background (#1A1A1A)
  static const Color surface = Color(0xFF1A1A1A);

  /// Elevated card / highlighted surface (#242424)
  static const Color surfaceElevated = Color(0xFF242424);

  /// Controls, inputs, and icon button backgrounds (#202020)
  static const Color surfaceInput = Color(0xFF202020);

  // --- Dark Mode Borders ---
  /// Standard dark border for cards and inputs (#2E2E2E)
  static const Color border = Color(0xFF2E2E2E);

  /// Secondary subtle divider border (#242424)
  static const Color borderSubtle = Color(0xFF242424);

  /// Darker border tone (#1C1C1C)
  static const Color borderDark = Color(0xFF1C1C1C);

  // --- Dark Mode Text & Foreground ---
  /// High-emphasis headline text (#F5F5F5)
  static const Color textPrimary = Color(0xFFF5F5F5);

  /// Muted secondary text for subtitles, placeholders, and metadata (#A0A0A0)
  static const Color textSecondary = Color(0xFFA0A0A0);

  /// Secondary muted grey text (#757575)
  static const Color textMuted = Color(0xFF757575);

  /// Pure white text (#FFFFFF)
  static const Color textLight = Color(0xFFFFFFFF);

  // --- Light Mode Surfaces & Backgrounds ---
  /// Global scaffold light background (#F8F9FA)
  static const Color lightBackground = Color(0xFFF8F9FA);

  /// Light card & item background (#FFFFFF)
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Light elevated card (#F1F3F5)
  static const Color lightSurfaceElevated = Color(0xFFF1F3F5);

  /// Light controls and inputs (#E9ECEF)
  static const Color lightSurfaceInput = Color(0xFFE9ECEF);

  /// Light primary container (#E8FDC0)
  static const Color lightPrimaryContainer = Color(0xFFE8FDC0);

  // --- Light Mode Borders ---
  /// Standard light border (#DEE2E6)
  static const Color lightBorder = Color(0xFFDEE2E6);

  /// Secondary subtle light divider border (#EEEEEE)
  static const Color lightBorderSubtle = Color(0xFFEEEEEE);

  // --- Light Mode Text & Foreground ---
  /// High-emphasis headline text (#1A1A1A)
  static const Color lightTextPrimary = Color(0xFF1A1A1A);

  /// Muted secondary text for light mode (#555555)
  static const Color lightTextSecondary = Color(0xFF555555);

  /// Muted grey text for light mode (#888888)
  static const Color lightTextMuted = Color(0xFF888888);

  // --- Alert & Status ---
  /// Hazard alert container background
  static const Color hazardContainer = Color(0xFF3B1212);

  /// Hazard alert text and icon tint
  static const Color hazardText = Color(0xFFFF6B6B);

  /// Warning accent (#F59E0B)
  static const Color warning = Color(0xFFF59E0B);

  // --- Theme-internal tones (previously unnamed literals) ---
  /// Dark-mode tinted lime container (#22300C)
  static const Color darkPrimaryContainer = Color(0xFF22300C);

  /// Light-mode deep lime used for text/icons on light surfaces (#3F5A06)
  static const Color lightAccent = Color(0xFF3F5A06);

  /// Light-mode secondary lime for tints and focus rings (#4C6D08)
  static const Color lightAccentSoft = Color(0xFF4C6D08);

  /// Light-mode hazard container (#FEE2E2)
  static const Color lightHazardContainer = Color(0xFFFEE2E2);

  /// Light-mode hazard text/icon (#B91C1C)
  static const Color lightHazardText = Color(0xFFB91C1C);

  /// Light-mode warning, darkened for contrast on white (#D97706)
  static const Color lightWarning = Color(0xFFD97706);

  // --- Effects & overlays ---
  /// Base shadow / scrim tone; apply alpha at call site.
  static const Color shadow = Color(0xFF000000);

  /// Text/icons drawn over photography (both themes).
  static const Color onImage = Color(0xFFFFFFFF);

  /// Secondary text/icons over photography (white @ 70%).
  static const Color onImageMuted = Color(0xB3FFFFFF);

  /// Legibility shadow behind text over photography (black @ 54%).
  static const Color imageTextShadow = Color(0x8A000000);

  // --- Third-party brand ---
  /// Google "G" sign-in mark (#4285F4)
  static const Color googleBlue = Color(0xFF4285F4);
}

/// Global border radiuses identified across ClimbMY frames.
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

  /// 20.0 - Feature cards (topo video card)
  static const double xl = 20.0;

  /// 28.0 - Floating bottom navigation bar
  static const double navBar = 28.0;

  /// 2.0 - Bottom-sheet drag handles
  static const double handle = 2.0;

  /// 9999.0 - Pill / Stadium buttons ("SUBMIT NEW ROUTE", "REPORT HAZARD")
  static const double pill = 9999.0;

  static const BorderRadius borderXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderNavBar = BorderRadius.all(Radius.circular(navBar));
  static const BorderRadius borderHandle = BorderRadius.all(Radius.circular(handle));
  static const BorderRadius borderPill = BorderRadius.all(Radius.circular(pill));

  /// Deliberately irregular "boulder" blob used by the indoor log calendar.
  static const BorderRadius borderBoulder = BorderRadius.only(
    topLeft: Radius.circular(14),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(10),
  );
}

/// Typography tokens combining Space Grotesk (headers) and JetBrains Mono (technical body/data).
class AppTextStyles {
  AppTextStyles._();

  // --- Space Grotesk (Headings & Display) ---
  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
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

  /// Climbing grade display style (e.g., '6b+', '7a', 'V4')
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

  /// Top-level screen title (Home "Crag", "Profile", "Post"): displayLarge at 28.
  static TextStyle screenTitle = displayLarge.copyWith(fontSize: 28);

  /// 9px badge / tag text: [caption] one step smaller (same weight & leading).
  static TextStyle micro = caption.copyWith(fontSize: 9);

  /// Emoji glyphs (hazard type icons). No font family: uses the platform emoji font.
  static const TextStyle emoji = TextStyle(fontSize: 22);
}

/// Brightness-aware semantic colours. **UI code must read colours from here**
/// (`context.palette.x`) rather than [AppColors], which holds raw constants
/// for building the themes.
///
/// [dark] mirrors the original dark-only palette 1:1 so dark mode is
/// visually unchanged; [light] supplies readable equivalents.
///
/// `primary` is a *fill* (buttons, selected chips). Use `accent` for lime
/// *foreground* (text, icons, borders): it stays lime in dark mode but becomes
/// deep olive in light mode, where lime-on-white is unreadable.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceInput,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textStrong,
    required this.primary,
    required this.onPrimary,
    required this.primaryVariant,
    required this.primaryLight,
    required this.primaryContainer,
    required this.accent,
    required this.hazardContainer,
    required this.hazardText,
    required this.warning,
    required this.shadow,
    required this.pressedOverlay,
    required this.iconDim,
    required this.onImage,
    required this.onImageMuted,
    required this.imageTextShadow,
    required this.googleBlue,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceInput;
  final Color border;
  final Color borderSubtle;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Highest-emphasis text/icons (pure white in dark, near-black in light).
  final Color textStrong;

  /// Brand lime *fill*.
  final Color primary;
  final Color onPrimary;
  final Color primaryVariant;

  /// Lime tint for foreground highlights (lighter in dark, deeper in light).
  final Color primaryLight;
  final Color primaryContainer;

  /// Brand lime *foreground* (text, icons, borders on surfaces).
  final Color accent;

  final Color hazardContainer;
  final Color hazardText;
  final Color warning;

  /// Shadow/scrim base; apply alpha at call site.
  final Color shadow;

  /// Ink highlight on pressed controls.
  final Color pressedOverlay;

  /// Very low-emphasis decorative icon dots.
  final Color iconDim;

  /// Foreground over photography (same in both themes).
  final Color onImage;
  final Color onImageMuted;
  final Color imageTextShadow;

  final Color googleBlue;

  static const AppPalette dark = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surfaceElevated,
    surfaceInput: AppColors.surfaceInput,
    border: AppColors.border,
    borderSubtle: AppColors.borderSubtle,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    textStrong: AppColors.textLight,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryVariant: AppColors.primaryVariant,
    primaryLight: AppColors.primaryLight,
    primaryContainer: AppColors.primaryContainer,
    accent: AppColors.primary,
    hazardContainer: AppColors.hazardContainer,
    hazardText: AppColors.hazardText,
    warning: AppColors.warning,
    shadow: AppColors.shadow,
    pressedOverlay: Color(0x0DFFFFFF), // white @ 5%
    iconDim: Color(0x3DFFFFFF), // white @ 24%
    onImage: AppColors.onImage,
    onImageMuted: AppColors.onImageMuted,
    imageTextShadow: AppColors.imageTextShadow,
    googleBlue: AppColors.googleBlue,
  );

  static const AppPalette light = AppPalette(
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceElevated: AppColors.lightSurfaceElevated,
    surfaceInput: AppColors.lightSurfaceInput,
    border: AppColors.lightBorder,
    borderSubtle: AppColors.lightBorderSubtle,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    textMuted: AppColors.lightTextMuted,
    textStrong: AppColors.lightTextPrimary,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryVariant: AppColors.primaryVariant,
    primaryLight: AppColors.lightAccentSoft,
    primaryContainer: AppColors.lightPrimaryContainer,
    accent: AppColors.lightAccent,
    hazardContainer: AppColors.lightHazardContainer,
    hazardText: AppColors.lightHazardText,
    warning: AppColors.lightWarning,
    shadow: AppColors.shadow,
    pressedOverlay: Color(0x0D000000), // black @ 5%
    iconDim: Color(0x42000000), // black @ 26%
    onImage: AppColors.onImage,
    onImageMuted: AppColors.onImageMuted,
    imageTextShadow: AppColors.imageTextShadow,
    googleBlue: AppColors.googleBlue,
  );

  /// Resolves the palette for [context]; falls back to [dark] if a widget is
  /// built outside an [AppTheme] (e.g. a bare test harness).
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? dark;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      surfaceInput: l(surfaceInput, other.surfaceInput),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textStrong: l(textStrong, other.textStrong),
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryVariant: l(primaryVariant, other.primaryVariant),
      primaryLight: l(primaryLight, other.primaryLight),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      accent: l(accent, other.accent),
      hazardContainer: l(hazardContainer, other.hazardContainer),
      hazardText: l(hazardText, other.hazardText),
      warning: l(warning, other.warning),
      shadow: l(shadow, other.shadow),
      pressedOverlay: l(pressedOverlay, other.pressedOverlay),
      iconDim: l(iconDim, other.iconDim),
      onImage: l(onImage, other.onImage),
      onImageMuted: l(onImageMuted, other.onImageMuted),
      imageTextShadow: l(imageTextShadow, other.imageTextShadow),
      googleBlue: l(googleBlue, other.googleBlue),
    );
  }
}

/// Brightness-aware text styles: every [AppTextStyles] entry with its colour
/// taken from an [AppPalette]. **UI code reads `context.textStyles.x`.**
@immutable
class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    required this.displayLarge,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.caption,
    required this.micro,
    required this.grade,
    required this.hazardAlert,
    required this.screenTitle,
    required this.emoji,
  });

  final TextStyle displayLarge;
  final TextStyle headlineLarge;
  final TextStyle headlineMedium;
  final TextStyle headlineSmall;
  final TextStyle titleLarge;
  final TextStyle titleMedium;
  final TextStyle titleSmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelMedium;
  final TextStyle labelSmall;
  final TextStyle caption;
  final TextStyle micro;
  final TextStyle grade;
  final TextStyle hazardAlert;
  final TextStyle screenTitle;
  final TextStyle emoji;

  /// Same roles as the original dark-only [AppTextStyles], recoloured by [p].
  factory AppTypography.fromPalette(AppPalette p) => AppTypography(
        displayLarge: AppTextStyles.displayLarge.copyWith(color: p.accent),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(color: p.textPrimary),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(color: p.textPrimary),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(color: p.textPrimary),
        titleLarge: AppTextStyles.titleLarge.copyWith(color: p.textStrong),
        titleMedium: AppTextStyles.titleMedium.copyWith(color: p.textPrimary),
        titleSmall: AppTextStyles.titleSmall.copyWith(color: p.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: p.textSecondary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: p.textSecondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: p.textSecondary),
        labelLarge: AppTextStyles.labelLarge.copyWith(color: p.onPrimary),
        labelMedium: AppTextStyles.labelMedium.copyWith(color: p.textPrimary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: p.primaryLight),
        caption: AppTextStyles.caption.copyWith(color: p.textSecondary),
        micro: AppTextStyles.micro.copyWith(color: p.textSecondary),
        grade: AppTextStyles.grade.copyWith(color: p.accent),
        hazardAlert: AppTextStyles.hazardAlert.copyWith(color: p.hazardText),
        screenTitle: AppTextStyles.screenTitle.copyWith(color: p.accent),
        emoji: AppTextStyles.emoji,
      );

  static AppTypography of(BuildContext context) =>
      Theme.of(context).extension<AppTypography>() ?? _fallback;

  static final AppTypography _fallback = AppTypography.fromPalette(AppPalette.dark);

  @override
  AppTypography copyWith() => this;

  @override
  AppTypography lerp(covariant AppTypography? other, double t) {
    if (other == null) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return AppTypography(
      displayLarge: l(displayLarge, other.displayLarge),
      headlineLarge: l(headlineLarge, other.headlineLarge),
      headlineMedium: l(headlineMedium, other.headlineMedium),
      headlineSmall: l(headlineSmall, other.headlineSmall),
      titleLarge: l(titleLarge, other.titleLarge),
      titleMedium: l(titleMedium, other.titleMedium),
      titleSmall: l(titleSmall, other.titleSmall),
      bodyLarge: l(bodyLarge, other.bodyLarge),
      bodyMedium: l(bodyMedium, other.bodyMedium),
      bodySmall: l(bodySmall, other.bodySmall),
      labelLarge: l(labelLarge, other.labelLarge),
      labelMedium: l(labelMedium, other.labelMedium),
      labelSmall: l(labelSmall, other.labelSmall),
      caption: l(caption, other.caption),
      micro: l(micro, other.micro),
      grade: l(grade, other.grade),
      hazardAlert: l(hazardAlert, other.hazardAlert),
      screenTitle: l(screenTitle, other.screenTitle),
      emoji: l(emoji, other.emoji),
    );
  }
}

/// Shorthand accessors for UI code.
extension AppThemeContext on BuildContext {
  /// Brightness-aware colours. Prefer this over [AppColors] in widgets.
  AppPalette get palette => AppPalette.of(this);

  /// Brightness-aware text styles. Prefer this over [AppTextStyles] in widgets.
  AppTypography get textStyles => AppTypography.of(this);
}

/// Material 3 ThemeData with #CFFF74 prime brand color and dynamic system display adaptability.
class AppTheme {
  AppTheme._();

  /// Dark Theme (Scaffold #121212, Cards #1A1A1A, Prime #CFFF74)
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
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
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
      extensions: <ThemeExtension<dynamic>>[
        AppPalette.dark,
        AppTypography.fromPalette(AppPalette.dark),
      ],
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

  /// Light Theme (Scaffold #F8F9FA, Cards #FFFFFF, Prime #CFFF74 / Dark Lime accents)
  static ThemeData get lightTheme {
    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.lightAccent),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.lightTextPrimary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.lightTextPrimary),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.lightTextPrimary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.lightTextPrimary),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.lightTextPrimary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.lightTextSecondary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextSecondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.onPrimary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.lightTextPrimary),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.lightAccentSoft),
    );

    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.lightAccentSoft,
      onSecondary: Colors.white,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceElevated,
      error: AppColors.lightHazardContainer,
      onError: AppColors.lightHazardText,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        AppPalette.light,
        AppTypography.fromPalette(AppPalette.light),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.lightTextPrimary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderSm,
          side: BorderSide(color: AppColors.lightBorder, width: 1.0),
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
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorder, width: 1.0),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.lightTextPrimary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.borderSm,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceInput,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.lightTextSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.borderSm,
          borderSide: BorderSide(color: AppColors.lightAccentSoft, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceInput,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.lightTextPrimary),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderXs,
          side: BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightAccent,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
