import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Raw brand palette. Screens should not use these directly — read colors from
/// `Theme.of(context).colorScheme` or `context.colors` (AppColors) instead, so
/// light and dark mode both work.
class AppPalette {
  static const cream = Color(0xFFEAE6E0);
  static const ink = Color(0xFF1B1B1B);
  static const black = Color(0xFF111111);
  static const steel = Color(0xFF818284);
  static const sand = Color(0xFFD3D3D3);
  static const night = Color(0xFF0F1011);
  static const nightSurface = Color(0xFF1A1B1D);
}

/// Spacing and radius scale used across the app.
class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

/// App-specific colors that Material's ColorScheme doesn't cover: the clock
/// dial, the floating nav bar and the muted category tints.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color dialFace;
  final Color dialTrack;
  final Color dialTick;
  final Color dialLabel;
  final Color dialHand;
  final Color onDialArc;
  final Color navBar;
  final Color navIcon;
  final Color navActive;
  final Color onNavActive;
  final Color success;

  /// Muted category tints; a category's `color` indexes into this list.
  final List<Color> categoryFill;

  /// Readable text/icon color for each tint on the app background.
  final List<Color> categoryText;

  const AppColors({
    required this.dialFace,
    required this.dialTrack,
    required this.dialTick,
    required this.dialLabel,
    required this.dialHand,
    required this.onDialArc,
    required this.navBar,
    required this.navIcon,
    required this.navActive,
    required this.onNavActive,
    required this.success,
    required this.categoryFill,
    required this.categoryText,
  });

  Color tint(int i) => categoryFill[i % categoryFill.length];
  Color tintOn(int i) => categoryText[i % categoryText.length];

  static const _tints = [
    Color(0xFF8FA3B8), // dusty blue
    Color(0xFF9DAF96), // muted sage
    Color(0xFFC4A092), // soft clay
    Color(0xFFC9B48A), // warm sand
    Color(0xFFA79BB8), // lavender grey
    Color(0xFF8FB0AE), // slate teal
    Color(0xFFC49AA6), // dusty rose
    Color(0xFFA8A67E), // olive
  ];

  static const light = AppColors(
    dialFace: Color(0xFF151515),
    dialTrack: Color(0x14FFFFFF),
    dialTick: Color(0x66FFFFFF),
    dialLabel: Color(0xB3FFFFFF),
    dialHand: AppPalette.cream,
    onDialArc: AppPalette.ink,
    navBar: AppPalette.black,
    navIcon: Color(0x99EAE6E0),
    navActive: AppPalette.cream,
    onNavActive: AppPalette.black,
    success: Color(0xFF5B6E54),
    categoryFill: _tints,
    categoryText: [
      Color(0xFF4E6378),
      Color(0xFF55684E),
      Color(0xFF8A5E4F),
      Color(0xFF7C6838),
      Color(0xFF625677),
      Color(0xFF4A6E6B),
      Color(0xFF85566A),
      Color(0xFF66643C),
    ],
  );

  static const dark = AppColors(
    dialFace: Color(0xFF1A1B1D),
    dialTrack: Color(0x12FFFFFF),
    dialTick: Color(0x55EAE6E0),
    dialLabel: Color(0x99EAE6E0),
    dialHand: AppPalette.cream,
    onDialArc: AppPalette.ink,
    navBar: Color(0xFF232427),
    navIcon: Color(0x99EAE6E0),
    navActive: AppPalette.cream,
    onNavActive: AppPalette.black,
    success: Color(0xFF9DAF96),
    categoryFill: _tints,
    categoryText: _tints,
  );

  @override
  AppColors copyWith({
    Color? dialFace,
    Color? dialTrack,
    Color? dialTick,
    Color? dialLabel,
    Color? dialHand,
    Color? onDialArc,
    Color? navBar,
    Color? navIcon,
    Color? navActive,
    Color? onNavActive,
    Color? success,
    List<Color>? categoryFill,
    List<Color>? categoryText,
  }) {
    return AppColors(
      dialFace: dialFace ?? this.dialFace,
      dialTrack: dialTrack ?? this.dialTrack,
      dialTick: dialTick ?? this.dialTick,
      dialLabel: dialLabel ?? this.dialLabel,
      dialHand: dialHand ?? this.dialHand,
      onDialArc: onDialArc ?? this.onDialArc,
      navBar: navBar ?? this.navBar,
      navIcon: navIcon ?? this.navIcon,
      navActive: navActive ?? this.navActive,
      onNavActive: onNavActive ?? this.onNavActive,
      success: success ?? this.success,
      categoryFill: categoryFill ?? this.categoryFill,
      categoryText: categoryText ?? this.categoryText,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> ll(List<Color> a, List<Color> b) =>
        List.generate(a.length, (i) => l(a[i], b[i]));
    return AppColors(
      dialFace: l(dialFace, other.dialFace),
      dialTrack: l(dialTrack, other.dialTrack),
      dialTick: l(dialTick, other.dialTick),
      dialLabel: l(dialLabel, other.dialLabel),
      dialHand: l(dialHand, other.dialHand),
      onDialArc: l(onDialArc, other.onDialArc),
      navBar: l(navBar, other.navBar),
      navIcon: l(navIcon, other.navIcon),
      navActive: l(navActive, other.navActive),
      onNavActive: l(onNavActive, other.onNavActive),
      success: l(success, other.success),
      categoryFill: ll(categoryFill, other.categoryFill),
      categoryText: ll(categoryText, other.categoryText),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
}

class AppTheme {
  static final ThemeData lightTheme = _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.black,
      onPrimary: AppPalette.cream,
      secondary: AppPalette.steel,
      onSecondary: Colors.white,
      tertiary: AppPalette.sand,
      onTertiary: AppPalette.ink,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: AppPalette.cream,
      onSurface: AppPalette.ink,
      onSurfaceVariant: Color(0xFF5C5D60),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFBFAF8),
      surfaceContainer: Color(0xFFF3F0EB),
      surfaceContainerHigh: Color(0xFFE2DDD5),
      surfaceContainerHighest: Color(0xFFD8D2C9),
      outline: Color(0xFFB9B3AA),
      outlineVariant: Color(0xFFDCD7CF),
      inverseSurface: AppPalette.black,
      onInverseSurface: AppPalette.cream,
      shadow: Colors.black,
    ),
    AppColors.light,
  );

  static final ThemeData darkTheme = _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppPalette.cream,
      onPrimary: AppPalette.black,
      secondary: Color(0xFFA3A4A7),
      onSecondary: AppPalette.black,
      tertiary: AppPalette.sand,
      onTertiary: AppPalette.ink,
      error: Color(0xFFF2827A),
      onError: AppPalette.black,
      surface: AppPalette.night,
      onSurface: AppPalette.cream,
      onSurfaceVariant: Color(0xFFA9AAAD),
      surfaceContainerLowest: Color(0xFF0B0C0D),
      surfaceContainerLow: AppPalette.nightSurface,
      surfaceContainer: Color(0xFF202124),
      surfaceContainerHigh: Color(0xFF2A2B2E),
      surfaceContainerHighest: Color(0xFF343538),
      outline: Color(0xFF4A4B4F),
      outlineVariant: Color(0xFF2C2D30),
      inverseSurface: AppPalette.cream,
      onInverseSurface: AppPalette.black,
      shadow: Colors.black,
    ),
    AppColors.dark,
  );

  static ThemeData _build(ColorScheme cs, AppColors colors) {
    final isDark = cs.brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    final text = GoogleFonts.fustatTextTheme(base.textTheme)
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
    final textTheme = text.copyWith(
      displaySmall: text.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
      headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.4),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
    );

    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
    final buttonText = textTheme.labelLarge?.copyWith(fontSize: 15);
    // Soft filled fields: no outline until focused (labels sit above, see AppTextField).
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      textTheme: textTheme,
      extensions: [colors],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: isDark ? 1 : 0.7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: inputBorder,
        enabledBorder: inputBorder,
        disabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: cs.primary, width: 1.5)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: cs.error)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: cs.error, width: 1.5)),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        floatingLabelStyle: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(64, 54),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          minimumSize: const Size(64, 54),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          minimumSize: const Size(64, 54),
          shape: rounded,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.onSurface,
          textStyle: buttonText,
          shape: rounded,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: cs.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainer,
        selectedColor: cs.primary,
        side: BorderSide(color: cs.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(color: cs.onSurface),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(color: cs.onPrimary),
        checkmarkColor: cs.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.onPrimary : cs.outline),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHigh),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : cs.outline),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? cs.primary : Colors.transparent),
        checkColor: WidgetStatePropertyAll(cs.onPrimary),
        side: BorderSide(color: cs.outline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? cs.primary : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurface),
          side: WidgetStatePropertyAll(BorderSide(color: cs.outlineVariant)),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? cs.surfaceContainerLow : cs.surface,
        modalBackgroundColor: isDark ? cs.surfaceContainerLow : cs.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: cs.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: cs.onInverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.bodyLarge,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 12,
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHigh,
        circularTrackColor: Colors.transparent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: isDark ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        dialBackgroundColor: cs.surfaceContainer,
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: isDark ? cs.surfaceContainerLow : cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: BorderRadius.circular(8)),
        textStyle: textTheme.bodySmall?.copyWith(color: cs.onInverseSurface),
      ),
    );
  }
}
