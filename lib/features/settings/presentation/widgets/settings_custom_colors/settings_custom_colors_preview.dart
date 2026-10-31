import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_preview_budget.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_preview_tap.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// A small diary day in the own [colors]: the budget card, a meal with a
/// plan, a snack bar and the scan button. A tap on a part picks the color
/// it shows.
class SettingsCustomColorsPreview extends StatelessWidget {
  /// Creates the preview.
  const new({
    required this.colors,
    required this.allMacrosColored,
    required this.onPick,
    super.key,
  });

  /// Key of the preview.
  static const previewKey = ValueKey<String>('settings-custom-colors-preview');

  /// The colors shown.
  final AppCustomColors colors;

  /// Whether every macro shows its color.
  final bool allMacrosColored;

  /// Called with the color of the tapped part.
  final ValueChanged<AppCustomColor> onPick;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.custom(colors)
          .withAllMacrosColored(value: allMacrosColored),
      // The preview shows colors, not text sizes: it keeps the normal size
      // and shrinks as a whole when room is short. The strip is the way to
      // pick for screen readers.
      child: MediaQuery.withNoTextScaling(
        child: ExcludeSemantics(
          child: SettingsCustomPreviewScope(
            onPick: onPick,
            child: const _Day(key: previewKey),
          ),
        ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return SettingsCustomPreviewTap(
      color: AppCustomColor.paper,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paper,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: colors.rule),
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.xs,
            children: [
              _SnackBar(),
              SettingsCustomPreviewBudget(),
              _Meal(),
              _Scan(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A lunch with one eaten food and one plan.
class _Meal extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colors = FoodLabelColors.of(context);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final body = textTheme.bodyMedium?.copyWith(color: colors.ink);

    Widget row(String name, int kcal, {bool planned = false}) {
      final style = planned ? body?.copyWith(color: colors.plan) : body;
      return SettingsCustomPreviewTap(
        color: planned ? AppCustomColor.plan : AppCustomColor.ink,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: colors.rule)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              spacing: AppSpacing.xs,
              children: [
                if (planned)
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    size: AppSpacing.xl,
                    color: colors.plan,
                  ),
                Expanded(child: Text(name, style: style)),
                Text(number.format(kcal), style: style),
              ],
            ),
          ),
        ),
      );
    }

    return SettingsCustomPreviewTap(
      color: AppCustomColor.card,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsCustomPreviewTap(
                color: AppCustomColor.ink,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(
                    l10n.caloriesMealLunch,
                    style: textTheme.titleSmall?.copyWith(color: colors.ink),
                  ),
                ),
              ),
              row(l10n.settingsCustomPreviewCurry, 540),
              row(l10n.settingsCustomPreviewBar, 210, planned: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app's snack bar on top, as after logging a food: the card tinted
/// with the accent, text, icon and action in the text color.
class _SnackBar extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    // The card picks the accent, its text and action the text color; the
    // action only shows.
    return SettingsCustomPreviewTap(
      color: AppCustomColor.accent,
      child: AppSnackBarCard(
        message: l10n.settingsCustomPreviewLogged,
        icon: Icons.check_circle,
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        actionLabel: l10n.commonUndoAction,
        onAction: () {},
        // Only the words pick the text color, not the room beside them.
        wrapText: (text) => Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: SettingsCustomPreviewTap(
            color: AppCustomColor.ink,
            child: text,
          ),
        ),
      ),
    );
  }
}

/// The accent scan button.
class _Scan extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SettingsCustomPreviewTap(
        color: AppCustomColor.accent,
        // The button only shows; the tap goes to the part around it.
        child: IgnorePointer(
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(l10n.settingsCustomPreviewScan),
          ),
        ),
      ),
    );
  }
}
