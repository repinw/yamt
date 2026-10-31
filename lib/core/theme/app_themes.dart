import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/core/theme/app_all_macros_colored_controller.dart';
import 'package:yamt/core/theme/app_custom_colors_controller.dart';
import 'package:yamt/core/theme/app_design_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

part 'app_themes.g.dart';

/// The themes of the app and which one shows, as `MaterialApp` takes them.
typedef AppThemes = ({ThemeData light, ThemeData dark, ThemeMode mode});

/// The themes of the design, accent, own colors and macro coloring the user
/// picked. "Individuell" shows the own colors whatever the system brightness
/// is.
@riverpod
AppThemes appThemes(Ref ref) {
  final design = ref.watch(appDesignControllerProvider);
  final custom = ref.watch(appCustomColorsControllerProvider);
  final allMacrosColored = ref.watch(appAllMacrosColoredControllerProvider);
  if (design == AppDesign.custom && custom != null) {
    final theme = AppTheme.custom(custom)
        .withAllMacrosColored(value: allMacrosColored);
    return (
      light: theme,
      dark: theme,
      mode: custom.base == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    );
  }
  final accent = ref.watch(appAccentControllerProvider);
  return (
    light: AppTheme.light(accent: accent)
        .withAllMacrosColored(value: allMacrosColored),
    dark: AppTheme.dark(accent: accent)
        .withAllMacrosColored(value: allMacrosColored),
    mode: switch (design) {
      AppDesign.light => ThemeMode.light,
      AppDesign.dark => ThemeMode.dark,
      AppDesign.system || AppDesign.custom => ThemeMode.system,
    },
  );
}
