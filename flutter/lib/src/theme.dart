import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFFFA3E2C);
  static const Color primaryContainer = Color(0xFFFFF0ED);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF3D0500);

  // Primary dark
  static const Color primaryDark = Color(0xFFFFB4AB);
  static const Color primaryContainerDark = Color(0xFF5E1400);
  static const Color onPrimaryDark = Color(0xFF3D0500);
  static const Color onPrimaryContainerDark = Color(0xFFFFDAD4);

  // Secondary colors
  static const Color secondary = Color(0xFF1B1B18);
  static const Color secondaryContainer = Color(0xFFE8E2DB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF0D0D0A);

  // Secondary dark
  static const Color secondaryDark = Color(0xFFCBC6BF);
  static const Color secondaryContainerDark = Color(0xFF2B2B28);
  static const Color onSecondaryDark = Color(0xFF0D0D0A);
  static const Color onSecondaryContainerDark = Color(0xFFE8E2DB);

  // Tertiary colors
  static const Color tertiary = Color(0xFF9D4B3C);
  static const Color tertiaryContainer = Color(0xFFFFDACD);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF3B0A00);

  // Tertiary dark
  static const Color tertiaryDark = Color(0xFFFFB4A0);
  static const Color tertiaryContainerDark = Color(0xFF7A3427);
  static const Color onTertiaryDark = Color(0xFF3B0A00);
  static const Color onTertiaryContainerDark = Color(0xFFFFDACD);

  // Surface colors
  static const Color surface = Color(0xFFFAF8F7);
  static const Color surfaceDim = Color(0xFFEEECEB);
  static const Color surfaceBright = Color(0xFFFAF8F7);
  static const Color onSurface = Color(0xFF1B1B18);
  static const Color onSurfaceVariant = Color(0xFF4B4A45);
  static const Color outline = Color(0xFF7A7975);
  static const Color outlineVariant = Color(0xFFCDC7BF);

  // Surface dark
  static const Color surfaceDark = Color(0xFF131310);
  static const Color surfaceDimDark = Color(0xFF131310);
  static const Color surfaceBrightDark = Color(0xFF3A3935);
  static const Color onSurfaceDark = Color(0xFFE4E2DC);
  static const Color onSurfaceVariantDark = Color(0xFFC8C2BA);
  static const Color outlineDark = Color(0xFF928C85);
  static const Color outlineVariantDark = Color(0xFF46443F);

  // Error colors
  static const Color error = Color(0xFFB02A1D);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410200);

  // Error dark
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color errorContainerDark = Color(0xFF93000A);
  static const Color onErrorDark = Color(0xFF601410);
  static const Color onErrorContainerDark = Color(0xFFFFDAD6);

  // Neutral colors
  static const Color scrim = Color(0xFF000000);
  static const Color inverseSurface = Color(0xFF303030);
  static const Color inverseOnSurface = Color(0xFFF4EFE9);
  static const Color inversePrimary = Color(0xFFFFB4AB);

  // Semantic colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color info = Color(0xFF2196F3);
  static const Color infoDark = Color(0xFF64B5F6);
  static const Color pending = Color(0xFFFFC107);

  // Disabled
  static const Color disabled = Color(0xFFC0C0C0);
  static const Color disabledBackground = Color(0xFFF5F5F5);
  static const Color disabledDark = Color(0xFF6B6B6B);
  static const Color disabledBackgroundDark = Color(0xFF2B2B28);
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
}

class AppTheme {
  static ThemeData _baseTheme({
    required Brightness brightness,
    required Color surface,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color outline,
    required Color outlineVariant,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color secondary,
    required Color onSecondary,
    required Color secondaryContainer,
    required Color onSecondaryContainer,
    required Color tertiary,
    required Color onTertiary,
    required Color tertiaryContainer,
    required Color onTertiaryContainer,
    required Color error,
    required Color onError,
    required Color errorContainer,
    required Color onErrorContainer,
    required Color inverseSurface,
    required Color inverseOnSurface,
    required Color inversePrimary,
    required Color disabled,
    required Color disabledBackground,
    required Color scrim,
  }) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      outline: outline,
      outlineVariant: outlineVariant,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
      scrim: scrim,
      surfaceTint: primary,
    );

    final textTheme = TextTheme(
      displayLarge: GoogleFonts.instrumentSans(fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: 0, color: onSurface),
      displayMedium: GoogleFonts.instrumentSans(fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: 0, color: onSurface),
      displaySmall: GoogleFonts.instrumentSans(fontSize: 36, fontWeight: FontWeight.w400, letterSpacing: 0, color: onSurface),
      headlineLarge: GoogleFonts.instrumentSans(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 0, color: onSurface),
      headlineMedium: GoogleFonts.instrumentSans(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 0, color: onSurface),
      headlineSmall: GoogleFonts.instrumentSans(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 0, color: onSurface),
      titleLarge: GoogleFonts.instrumentSans(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 0, color: onSurface),
      titleMedium: GoogleFonts.instrumentSans(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15, color: onSurface),
      titleSmall: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: onSurface),
      bodyLarge: GoogleFonts.instrumentSans(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15, color: onSurface),
      bodyMedium: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: onSurfaceVariant),
      bodySmall: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: onSurfaceVariant),
      labelLarge: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: onSurface),
      labelMedium: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: onSurface),
      labelSmall: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: onSurface),
    );

    final buttonTextStyle = GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: false,
        titleSpacing: AppSpacing.md,
        toolbarHeight: 56,
        iconTheme: IconThemeData(color: onSurface),
        actionsIconTheme: IconThemeData(color: onSurface),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabled,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: buttonTextStyle,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: disabled,
          side: BorderSide(color: outline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: buttonTextStyle,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: disabled,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: buttonTextStyle,
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: outlineVariant),
        ),
        labelStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w500, color: onSurfaceVariant),
        hintStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w400, color: onSurfaceVariant),
        errorStyle: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w400, color: error),
      ),

      // Card
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: scrim.withValues(alpha: isLight ? 0.08 : 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: outlineVariant),
        ),
        margin: const EdgeInsets.all(0),
        clipBehavior: Clip.hardEdge,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: surface,
        elevation: 3,
        shadowColor: scrim.withValues(alpha: isLight ? 0.15 : 0.4),
        titleTextStyle: GoogleFonts.instrumentSans(fontSize: 24, fontWeight: FontWeight.w700, color: onSurface),
        contentTextStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w400, color: onSurfaceVariant),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 4,
        hoverElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 1,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.hardEdge,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: primaryContainer,
        deleteIconColor: primary,
        disabledColor: disabledBackground,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selectedColor: primary,
        secondarySelectedColor: secondary,
        side: BorderSide(color: outlineVariant),
        labelStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
      ),

      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearMinHeight: 4,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inverseSurface,
        contentTextStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w400, color: inverseOnSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        indicatorColor: primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: primary);
          return const IconThemeData(color: Color(0xFF4B4A45));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface);
          }
          return GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant);
        }),
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        minLeadingWidth: 40,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: AppSpacing.md,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.3);
          return outlineVariant;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return outline;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: outline),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return onSurfaceVariant;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: outlineVariant,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        valueIndicatorColor: primary,
        valueIndicatorTextStyle: GoogleFonts.instrumentSans(fontSize: 12, color: onPrimary),
      ),

      // Expansion Tile
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: onSurfaceVariant,
        collapsedIconColor: onSurfaceVariant,
        textColor: onSurface,
        collapsedTextColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.instrumentSans(fontSize: 12, color: inverseOnSurface),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: onSurfaceVariant),
        selectedLabelTextStyle: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface),
        unselectedLabelTextStyle: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant),
      ),

      // Dropdown Menu
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: outline),
          ),
        ),
      ),

      // Badge
      badgeTheme: BadgeThemeData(
        backgroundColor: error,
        textColor: onError,
        textStyle: GoogleFonts.instrumentSans(fontSize: 11, fontWeight: FontWeight.w600),
      ),

      // Search Bar
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(surface),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
        side: WidgetStateProperty.all(BorderSide(color: outlineVariant)),
        textStyle: WidgetStateProperty.all(GoogleFonts.instrumentSans(fontSize: 14, color: onSurface)),
        hintStyle: WidgetStateProperty.all(GoogleFonts.instrumentSans(fontSize: 14, color: onSurfaceVariant)),
      ),

      // Segmented Button
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: onSurfaceVariant,
          selectedForegroundColor: primary,
          selectedBackgroundColor: primaryContainer,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: outlineVariant),
        ),
      ),

      // Date Picker
      datePickerTheme: DatePickerThemeData(
        backgroundColor: surface,
        headerBackgroundColor: primary,
        headerForegroundColor: onPrimary,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return onPrimary;
          return onSurface;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),

      // Menu
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          elevation: WidgetStateProperty.all(3),
        ),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primary,
        labelStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData lightTheme() => _baseTheme(
    brightness: Brightness.light,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    tertiaryContainer: AppColors.tertiaryContainer,
    onTertiaryContainer: AppColors.onTertiaryContainer,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    inverseSurface: AppColors.inverseSurface,
    inverseOnSurface: AppColors.inverseOnSurface,
    inversePrimary: AppColors.inversePrimary,
    disabled: AppColors.disabled,
    disabledBackground: AppColors.disabledBackground,
    scrim: AppColors.scrim,
  );

  static ThemeData darkTheme() => _baseTheme(
    brightness: Brightness.dark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    onSurfaceVariant: AppColors.onSurfaceVariantDark,
    outline: AppColors.outlineDark,
    outlineVariant: AppColors.outlineVariantDark,
    primary: AppColors.primaryDark,
    onPrimary: AppColors.onPrimaryDark,
    primaryContainer: AppColors.primaryContainerDark,
    onPrimaryContainer: AppColors.onPrimaryContainerDark,
    secondary: AppColors.secondaryDark,
    onSecondary: AppColors.onSecondaryDark,
    secondaryContainer: AppColors.secondaryContainerDark,
    onSecondaryContainer: AppColors.onSecondaryContainerDark,
    tertiary: AppColors.tertiaryDark,
    onTertiary: AppColors.onTertiaryDark,
    tertiaryContainer: AppColors.tertiaryContainerDark,
    onTertiaryContainer: AppColors.onTertiaryContainerDark,
    error: AppColors.errorDark,
    onError: AppColors.onErrorDark,
    errorContainer: AppColors.errorContainerDark,
    onErrorContainer: AppColors.onErrorContainerDark,
    inverseSurface: AppColors.surfaceBright,
    inverseOnSurface: AppColors.onSurface,
    inversePrimary: AppColors.primary,
    disabled: AppColors.disabledDark,
    disabledBackground: AppColors.disabledBackgroundDark,
    scrim: AppColors.scrim,
  );
}
