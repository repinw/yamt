import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

/// Centralized app themes for light and dark modes.
///
/// The themes follow the Graphit design language: one font (Plus Jakarta
/// Sans) where the weight separates names and numbers from text, one lime
/// main button, and rounded controls on soft surfaces without frames.
abstract final class AppTheme {
  /// Builds standard light Material 3 theme with Graphit colors.
  static ThemeData light() {
    const labelColors = FoodLabelColors.light;
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: labelColors.accent,
      onPrimary: labelColors.onAccent,
      primaryContainer: const Color(0xFFE2F78A),
      onPrimaryContainer: labelColors.ink,
      secondary: labelColors.accentText,
      onSecondary: const Color(0xFFFFFFFF),
      // A step below the white card, so tonal buttons show on cards, sheets
      // and the paper page alike.
      secondaryContainer: const Color(0xFFDCDCD7),
      onSecondaryContainer: labelColors.ink,
      tertiary: const Color(0xFF3B82F6),
      onTertiary: const Color(0xFFFFFFFF),
      error: const Color(0xFFBA1A1A),
      onError: const Color(0xFFFFFFFF),
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: labelColors.paper,
      onSurface: labelColors.ink,
      onSurfaceVariant: labelColors.muted,
      surfaceContainerLowest: labelColors.tile,
      surfaceContainerLow: labelColors.card,
      surfaceContainer: const Color(0xFFF4F4F1),
      surfaceContainerHigh: const Color(0xFFEEEEEC),
      surfaceContainerHighest: const Color(0xFFE5E5E1),
      outline: const Color(0xFF757571),
      outlineVariant: labelColors.rule,
      shadow: labelColors.ink,
    );

    return _theme(colorScheme, labelColors);
  }

  /// Builds standard dark Material 3 theme with Graphit colors.
  static ThemeData dark() {
    const labelColors = FoodLabelColors.dark;
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: labelColors.accent,
      onPrimary: labelColors.onAccent,
      primaryContainer: const Color(0xFF3B4D00),
      onPrimaryContainer: labelColors.accentText,
      secondary: labelColors.accentText,
      onSecondary: labelColors.onAccent,
      secondaryContainer: labelColors.tile,
      onSecondaryContainer: labelColors.ink,
      tertiary: const Color(0xFF60A5FA),
      onTertiary: const Color(0xFF003258),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: labelColors.paper,
      onSurface: labelColors.ink,
      onSurfaceVariant: labelColors.muted,
      surfaceContainerLowest: const Color(0xFF0C0C0C),
      surfaceContainerLow: labelColors.card,
      surfaceContainer: const Color(0xFF212222),
      surfaceContainerHigh: const Color(0xFF272828),
      surfaceContainerHighest: const Color(0xFF333434),
      outline: const Color(0xFF8A8A85),
      outlineVariant: labelColors.rule,
      shadow: const Color(0xFF000000),
    );

    return _theme(colorScheme, labelColors);
  }
}

/// Weights of the Graphit type scale: 800 for titles, names and numbers,
/// 600 to 700 for actions and labels, and the default 400 for text.
const _textWeights = TextTheme(
  displayLarge: TextStyle(fontWeight: FontWeight.w800),
  displayMedium: TextStyle(fontWeight: FontWeight.w800),
  displaySmall: TextStyle(fontWeight: FontWeight.w800),
  headlineLarge: TextStyle(fontWeight: FontWeight.w800),
  headlineMedium: TextStyle(fontWeight: FontWeight.w800),
  headlineSmall: TextStyle(fontWeight: FontWeight.w800),
  titleLarge: TextStyle(fontWeight: FontWeight.w800),
  titleMedium: TextStyle(fontWeight: FontWeight.w700),
  titleSmall: TextStyle(fontWeight: FontWeight.w700),
  labelLarge: TextStyle(fontWeight: FontWeight.w700),
  labelMedium: TextStyle(fontWeight: FontWeight.w600),
  labelSmall: TextStyle(fontWeight: FontWeight.w600),
);

/// Rounded shape of buttons, icon buttons and other controls.
const _controlShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
);

const _controlMinimumSize = Size(AppSizes.minTapTarget, AppSizes.minTapTarget);

const _buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.xxl);

ThemeData _theme(ColorScheme colorScheme, FoodLabelColors labelColors) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: colorScheme.brightness,
    colorScheme: colorScheme,
    fontFamily: AppFonts.sans,
    textTheme: _textWeights,
    scaffoldBackgroundColor: colorScheme.surface,
    dividerColor: colorScheme.outlineVariant,
    extensions: [
      labelColors,
      MetricAccentColors.fromColorScheme(colorScheme),
    ],
  );
  final buttonLabel = base.textTheme.labelLarge;

  return base.copyWith(
    appBarTheme: AppBarThemeData(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    // Colors stay with the defaults, so FilledButton is lime and
    // FilledButton.tonal sits on the soft secondaryContainer surface.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: _controlMinimumSize,
        padding: _buttonPadding,
        shape: _controlShape,
        textStyle: buttonLabel,
      ),
    ),
    // Outlined buttons look like tonal buttons: no frame around a button.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        disabledBackgroundColor: colorScheme.onSurface.withValues(
          alpha: AppOpacities.disabledContainer,
        ),
        disabledForegroundColor: colorScheme.onSurface.withValues(
          alpha: AppOpacities.disabledContent,
        ),
        side: BorderSide.none,
        minimumSize: _controlMinimumSize,
        padding: _buttonPadding,
        shape: _controlShape,
        textStyle: buttonLabel,
      ),
    ),
    // The quiet action: ink text with an underline instead of lime text.
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        minimumSize: _controlMinimumSize,
        shape: _controlShape,
        textStyle: buttonLabel?.copyWith(
          decoration: TextDecoration.underline,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: _controlShape),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.secondaryContainer,
      selectedColor: colorScheme.onSurface,
      checkmarkColor: colorScheme.surface,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: buttonLabel?.copyWith(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colorScheme.surface
              : colorScheme.onSurface,
        ),
      ),
    ),
    // Switches are ink, because lime marks only one thing per screen.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => _switchColor(
          states,
          colorScheme,
          selected: colorScheme.surface,
          unselected: colorScheme.onSurfaceVariant,
        ),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => _switchColor(
          states,
          colorScheme,
          selected: colorScheme.onSurface,
          unselected: colorScheme.outlineVariant,
        ),
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    // Sheets and dialogs sit on the card color, one step below the tonal
    // button surface.
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
    ),
  );
}

Color _switchColor(
  Set<WidgetState> states,
  ColorScheme colorScheme, {
  required Color selected,
  required Color unselected,
}) {
  final color = states.contains(WidgetState.selected) ? selected : unselected;
  if (states.contains(WidgetState.disabled)) {
    return color.withValues(alpha: AppOpacities.disabledContent);
  }
  return color;
}
