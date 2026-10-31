import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Name of [color] in the user's language.
String settingsCustomColorLabel(AppLocalizations l10n, AppCustomColor color) {
  return switch (color) {
    AppCustomColor.paper => l10n.settingsCustomColorPaper,
    AppCustomColor.card => l10n.settingsCustomColorCard,
    AppCustomColor.ink => l10n.settingsCustomColorInk,
    AppCustomColor.muted => l10n.settingsCustomColorMuted,
    AppCustomColor.lines => l10n.settingsCustomColorLines,
    AppCustomColor.accent => l10n.settingsCustomColorAccent,
    AppCustomColor.plan => l10n.settingsCustomColorPlan,
    AppCustomColor.protein => l10n.caloriesProteinLabel,
    AppCustomColor.carbs => l10n.diaryBudgetCarbsLabel,
    AppCustomColor.fat => l10n.caloriesFatLabel,
    AppCustomColor.signal => l10n.settingsCustomColorSignal,
  };
}

/// The order of the strip: the colors people change most come first.
const List<AppCustomColor> _order = [
  AppCustomColor.protein,
  AppCustomColor.carbs,
  AppCustomColor.fat,
  AppCustomColor.plan,
  AppCustomColor.accent,
  AppCustomColor.signal,
  AppCustomColor.paper,
  AppCustomColor.card,
  AppCustomColor.ink,
  AppCustomColor.muted,
  AppCustomColor.lines,
];

/// A row of round swatches, one per color, that scrolls sideways. A tap
/// opens the picker of that color.
class SettingsCustomColorStrip extends StatelessWidget {
  /// Creates the strip.
  const new({required this.colors, required this.onSelected, super.key});

  /// Key of the swatch of [color].
  static Key swatchKey(AppCustomColor color) =>
      ValueKey('settings-custom-color-${color.name}');

  /// The colors shown.
  final AppCustomColors colors;

  /// Called with the tapped color.
  final ValueChanged<AppCustomColor> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          for (final color in _order)
            SizedBox(
              width: AppSizes.customColorChipWidth,
              child: Semantics(
                button: true,
                child: AppInkWell(
                  key: swatchKey(color),
                  onTap: () => onSelected(color),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      spacing: AppSpacing.xs,
                      children: [
                        SettingsCustomColorSwatch(color: colors[color]),
                        Text(
                          settingsCustomColorLabel(l10n, color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A round swatch of [color] with a thin ring, so it shows on any ground.
class SettingsCustomColorSwatch extends StatelessWidget {
  /// Creates the swatch.
  const new({required this.color, super.key});

  /// The color shown.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.customColorSwatch,
      height: AppSizes.customColorSwatch,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}
