import 'package:flutter/material.dart';

import 'avahi_colors.dart';
import 'avahi_radius.dart';
import 'avahi_spacing.dart';
import 'avahi_typography.dart';

/// نقطة التجميع النهائية لنظام التصميم؛ يبني كائنَي [ThemeData] كاملين
/// (فاتح وداكن) بالاعتماد على Material 3 ونظام الألوان/الطباعة/المسافات
/// المعرَّف في هذا المجلد.
abstract class AvahiTheme {
  /// الثيم الفاتح (Light Theme).
  static ThemeData get light => _build(AvahiColors.light);

  /// الثيم الداكن (Dark Theme).
  static ThemeData get dark => _build(AvahiColors.dark);

  static ThemeData _build(AvahiColors colors) {
    final ColorScheme colorScheme = ColorScheme(
      brightness: colors.brightness,
      primary: colors.brand,
      onPrimary: colors.brandOnBrand,
      primaryContainer: colors.brandContainer,
      onPrimaryContainer: colors.onBrandContainer,
      secondary: colors.info,
      onSecondary: colors.onInfo,
      secondaryContainer: colors.infoContainer,
      onSecondaryContainer: colors.onInfoContainer,
      tertiary: colors.warning,
      onTertiary: colors.onWarning,
      tertiaryContainer: colors.warningContainer,
      onTertiaryContainer: colors.onWarningContainer,
      error: colors.danger,
      onError: colors.onDanger,
      errorContainer: colors.dangerContainer,
      onErrorContainer: colors.onDangerContainer,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceContainerHighest: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      shadow: colors.shadow,
      scrim: colors.scrim,
      inverseSurface: colors.onSurface,
      onInverseSurface: colors.surface,
      inversePrimary: colors.brandContainer,
    );

    final TextTheme baseTextTheme = colors.brightness == Brightness.dark
        ? Typography.whiteMountainView
        : Typography.blackMountainView;

    final TextTheme textTheme =
        AvahiTypography.primary(baseTextTheme, colors.onBackground);

    return ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      fontFamily: AvahiTypography.primary(baseTextTheme, colors.onBackground)
          .bodyMedium
          ?.fontFamily,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,

      // ── AppBar ──────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: colors.surface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: colors.onSurface),
      ),

      // ── Card ────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AvahiRadius.radiusMd,
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),

      // ── ElevatedButton ──────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.brand,
          foregroundColor: colors.brandOnBrand,
          disabledBackgroundColor: colors.disabled,
          disabledForegroundColor: colors.onDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AvahiSpacing.lg,
            vertical: AvahiSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AvahiRadius.radiusSm),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.brand,
          disabledForegroundColor: colors.onDisabled,
          side: BorderSide(color: colors.outline),
          padding: const EdgeInsets.symmetric(
            horizontal: AvahiSpacing.lg,
            vertical: AvahiSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AvahiRadius.radiusSm),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── TextButton ──────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brand,
          disabledForegroundColor: colors.onDisabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AvahiSpacing.md,
            vertical: AvahiSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AvahiRadius.radiusSm),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // ── InputDecoration (حقول الإدخال) ───────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AvahiSpacing.md,
          vertical: AvahiSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AvahiRadius.radiusSm,
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AvahiRadius.radiusSm,
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AvahiRadius.radiusSm,
          borderSide: BorderSide(color: colors.brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AvahiRadius.radiusSm,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AvahiRadius.radiusSm,
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colors.danger),
      ),

      // ── Divider ─────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── Dialog ──────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: colors.surfaceElevated,
        shape: const RoundedRectangleBorder(borderRadius: AvahiRadius.radiusMd),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // ── BottomSheet ─────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceElevated,
        surfaceTintColor: colors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AvahiRadius.lg),
          ),
        ),
      ),

      // ── Chip (يُستخدم أساساً من قبل status_badge) ────────────
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AvahiSpacing.xs,
          vertical: AvahiSpacing.xxs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AvahiRadius.radiusFull),
        side: BorderSide.none,
      ),

      // ── ProgressIndicator ───────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.brand,
        linearTrackColor: colors.surfaceVariant,
        circularTrackColor: colors.surfaceVariant,
      ),

      // ── SnackBar ────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.onSurface,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: colors.surface),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AvahiRadius.radiusSm),
      ),

      // ── Icon ────────────────────────────────────────────────
      iconTheme: IconThemeData(color: colors.onSurfaceVariant, size: 24),

      // ── Tooltip ─────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.onSurface,
          borderRadius: AvahiRadius.radiusXs,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: colors.surface),
      ),
    );
  }
}
