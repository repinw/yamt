import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks whether the own colors start as a copy of the light or the dark
/// design. Returns the picked brightness, or null on cancel.
Future<Brightness?> showSettingsCustomBaseDialog(BuildContext context) {
  return showDialog<Brightness>(
    context: context,
    builder: (context) => const SettingsCustomBaseDialog(),
  );
}

/// The dialog with a small sample of the light and the dark design.
class SettingsCustomBaseDialog extends ConsumerWidget {
  /// Creates the dialog.
  const new({super.key});

  /// Key of the option for [base].
  static Key optionKey(Brightness base) =>
      ValueKey('settings-custom-base-${base.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final accent = ref.watch(appAccentControllerProvider);

    return AlertDialog(
      title: Text(l10n.settingsCustomBaseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xl,
        children: [
          Text(l10n.settingsCustomBaseMessage),
          Row(
            spacing: AppSpacing.md,
            children: [
              for (final (base, theme, label) in [
                (
                  Brightness.light,
                  AppTheme.light(accent: accent),
                  l10n.settingsThemeModeLight,
                ),
                (
                  Brightness.dark,
                  AppTheme.dark(accent: accent),
                  l10n.settingsThemeModeDark,
                ),
              ])
                Expanded(
                  child: Theme(
                    data: theme,
                    child: _BaseOption(
                      key: optionKey(base),
                      label: label,
                      onTap: () => Navigator.of(context).pop(base),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ],
    );
  }
}

/// A sample card of one design: its paper, card, accent and macro colors.
class _BaseOption extends StatelessWidget {
  const new({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final metrics = MetricAccentColors.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: colors.paper,
      borderRadius: radius,
      child: AppInkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    spacing: AppSpacing.xxs,
                    children: [
                      for (final color in [
                        colors.accent,
                        metrics.protein,
                        metrics.carbs,
                        metrics.fat,
                      ])
                        _Dot(color: color),
                    ],
                  ),
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: colors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const new({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: AppSizes.customColorDot,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
