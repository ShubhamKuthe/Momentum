import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'typography.dart';

class AppColors {
  static const ink = Color(0xFF14161D);
  static const inkSoft = Color(0xFF20232C);
  static const inkLine = Color(0xFF323640);
  static const paper = Color(0xFFF6F3ED);
  static const card = Color(0xFFFFFFFF);
  static const paperDim = Color(0xFFEBE7DE);
  static const line = Color(0xFFE0DBD0);
  static const ember = Color(0xFFFF5B4D);
  static const emberDim = Color(0xFFFFE7DF);
  static const moss = Color(0xFF3E8F63);
  static const mossDim = Color(0xFFDDF1E5);
  static const gold = Color(0xFFE3A93C);
  static const goldDim = Color(0xFFF5E7C9);
  static const slate = Color(0xFF717784);
  static const inkText = Color(0xFF1F2430);
}

class AppDarkColors {
  static const background = Color(0xFF0B0C10);
  static const surface = Color(0xFF17191F);
  static const surfaceStrong = Color(0xFF21242C);
  static const surfaceMuted = Color(0xFF2A2E38);
  static const border = Color(0xFF2B303A);
  static const borderSoft = Color(0xFF3B414D);
  static const text = Color(0xFFF4F5F7);
  static const textSoft = Color(0xFFB0B5BE);
  static const textMuted = Color(0xFF878D98);
  static const ringTrack = Color(0xFF2A2F38);
  static const nav = Color(0xFF1A1C25);
}

@immutable
class MomentumPalette extends ThemeExtension<MomentumPalette> {
  const MomentumPalette({
    required this.background,
    required this.surface,
    required this.surfaceStrong,
    required this.surfaceMuted,
    required this.border,
    required this.borderSoft,
    required this.text,
    required this.textSoft,
    required this.textMuted,
    required this.ringTrack,
    required this.nav,
    required this.shadow,
    required this.gloss,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.successSoft,
    required this.gold,
    required this.goldSoft,
  });

  final Color background;
  final Color surface;
  final Color surfaceStrong;
  final Color surfaceMuted;
  final Color border;
  final Color borderSoft;
  final Color text;
  final Color textSoft;
  final Color textMuted;
  final Color ringTrack;
  final Color nav;
  final Color shadow;
  final Color gloss;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color successSoft;
  final Color gold;
  final Color goldSoft;

  static const light = MomentumPalette(
    background: AppColors.paper,
    surface: Color(0xFFFFFEFC),
    surfaceStrong: AppColors.card,
    surfaceMuted: Color(0xFFF2EEE6),
    border: AppColors.line,
    borderSoft: Color(0xFFF2EDE3),
    text: AppColors.inkText,
    textSoft: AppColors.slate,
    textMuted: Color(0xFF969CA8),
    ringTrack: AppColors.paperDim,
    nav: Color(0xFFF9F6F0),
    shadow: Color(0x14000000),
    gloss: Color(0x33FFFFFF),
    accent: AppColors.ember,
    accentSoft: AppColors.emberDim,
    success: AppColors.moss,
    successSoft: AppColors.mossDim,
    gold: AppColors.gold,
    goldSoft: AppColors.goldDim,
  );

  static const dark = MomentumPalette(
    background: AppDarkColors.background,
    surface: AppDarkColors.surface,
    surfaceStrong: AppDarkColors.surfaceStrong,
    surfaceMuted: AppDarkColors.surfaceMuted,
    border: AppDarkColors.border,
    borderSoft: AppDarkColors.borderSoft,
    text: AppDarkColors.text,
    textSoft: AppDarkColors.textSoft,
    textMuted: AppDarkColors.textMuted,
    ringTrack: AppDarkColors.ringTrack,
    nav: AppDarkColors.nav,
    shadow: Color(0xCC060709),
    gloss: Color(0x1AFFFFFF),
    accent: AppColors.ember,
    accentSoft: Color(0xFF34201B),
    success: Color(0xFF34C759),
    successSoft: Color(0xFF173523),
    gold: Color(0xFFFFD60A),
    goldSoft: Color(0xFF352B05),
  );

  @override
  MomentumPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceStrong,
    Color? surfaceMuted,
    Color? border,
    Color? borderSoft,
    Color? text,
    Color? textSoft,
    Color? textMuted,
    Color? ringTrack,
    Color? nav,
    Color? shadow,
    Color? gloss,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? successSoft,
    Color? gold,
    Color? goldSoft,
  }) {
    return MomentumPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      text: text ?? this.text,
      textSoft: textSoft ?? this.textSoft,
      textMuted: textMuted ?? this.textMuted,
      ringTrack: ringTrack ?? this.ringTrack,
      nav: nav ?? this.nav,
      shadow: shadow ?? this.shadow,
      gloss: gloss ?? this.gloss,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
    );
  }

  @override
  ThemeExtension<MomentumPalette> lerp(
    covariant ThemeExtension<MomentumPalette>? other,
    double t,
  ) {
    if (other is! MomentumPalette) {
      return this;
    }
    return MomentumPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      gloss: Color.lerp(gloss, other.gloss, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get theme => lightTheme;

  static ThemeData get lightTheme =>
      _buildTheme(brightness: Brightness.light, palette: MomentumPalette.light);

  static ThemeData get darkTheme =>
      _buildTheme(brightness: Brightness.dark, palette: MomentumPalette.dark);

  static ThemeData _buildTheme({
    required Brightness brightness,
    required MomentumPalette palette,
  }) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    );
    final platformTextTheme = _platformTextTheme(baseTheme.textTheme);
    final typeTheme = MomentumTypography.build(
      platformTextTheme,
      textColor: palette.text,
      mutedColor: palette.textSoft,
      captionColor: palette.textMuted,
    );
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
    ).copyWith(
      primary: palette.accent,
      secondary: palette.success,
      surface: palette.surface,
      onSurface: palette.text,
      outline: palette.border,
      outlineVariant: palette.borderSoft,
    );

    return ThemeData(
      useMaterial3: true,
      textTheme: typeTheme,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[palette],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _MomentumPageTransitionsBuilder(),
          TargetPlatform.iOS: _MomentumPageTransitionsBuilder(),
          TargetPlatform.macOS: _MomentumPageTransitionsBuilder(),
          TargetPlatform.windows: _MomentumPageTransitionsBuilder(),
          TargetPlatform.linux: _MomentumPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: palette.accent,
        scaffoldBackgroundColor: palette.background,
        barBackgroundColor: palette.background,
        textTheme: CupertinoTextThemeData(
          textStyle: typeTheme.bodyLarge,
          navTitleTextStyle: typeTheme.titleLarge,
          navLargeTitleTextStyle: typeTheme.displayMedium,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: typeTheme.displayMedium,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: palette.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
          side: BorderSide(color: palette.borderSoft.withValues(alpha: 0.8)),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.modal),
          side: BorderSide(color: palette.borderSoft.withValues(alpha: 0.8)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.borderSoft.withValues(alpha: brightness == Brightness.dark ? 0.7 : 1),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark ? palette.surfaceStrong : palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: 14,
        ),
        constraints: const BoxConstraints(minHeight: AppHeights.field),
        hintStyle: typeTheme.bodyMedium?.copyWith(color: palette.textMuted),
        labelStyle: typeTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: palette.textSoft,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.field),
          borderSide: BorderSide(color: palette.accent, width: 1.3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppHeights.button),
          elevation: 0,
          shadowColor: Colors.transparent,
          backgroundColor: palette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: typeTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppHeights.button),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          foregroundColor: palette.text,
          backgroundColor: brightness == Brightness.dark
              ? palette.surfaceStrong
              : palette.surfaceStrong,
          textStyle: typeTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.text,
        contentTextStyle: typeTheme.bodyLarge?.copyWith(
          color: palette.background,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.success
              : palette.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => Colors.transparent,
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: AppHeights.row,
        minVerticalPadding: AppSpacing.x2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x1,
        ),
        titleTextStyle: typeTheme.titleMedium,
        subtitleTextStyle: typeTheme.bodyMedium,
      ),
    );
  }

  static TextTheme _platformTextTheme(TextTheme base) {
    return base;
  }
}

extension MomentumThemeContext on BuildContext {
  MomentumPalette get momentum => Theme.of(this).extension<MomentumPalette>()!;

  bool get isMomentumDark => Theme.of(this).brightness == Brightness.dark;
}

class _MomentumPageTransitionsBuilder extends PageTransitionsBuilder {
  const _MomentumPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppEasing.standard,
      reverseCurve: Curves.easeInOut,
    );
    final offsetTween = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: curved.drive(offsetTween),
        child: child,
      ),
    );
  }
}
