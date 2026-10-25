import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The "Verwerfen" and "In Vorrat" buttons under the "Gekocht" page.
class CookedMealSaveBar extends StatelessWidget {
  /// Creates the bar; [onSave] and [onDiscard] are `null` while the meal
  /// cannot be saved or discarded.
  const new({required this.onSave, required this.onDiscard, super.key});

  /// Key of the button.
  static const saveKey = ValueKey<String>('cooked-save');

  /// Key of the "Verwerfen" button.
  static const discardKey = ValueKey<String>('cooked-discard');

  /// Saves the meal, or `null` to turn the button off.
  final VoidCallback? onSave;

  /// Discards the meal, or `null` to turn the button off.
  final VoidCallback? onDiscard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          TextButton(
            key: discardKey,
            onPressed: onDiscard,
            style: TextButton.styleFrom(
              foregroundColor: colors.ink,
              minimumSize: const Size(0, AppGraphit.buttonHeight),
            ),
            child: Text(l10n.freeCookingDiscardAction),
          ),
          Expanded(
            child: FilledButton(
              key: saveKey,
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              child: Text(l10n.cookedSave),
            ),
          ),
        ],
      ),
    );
  }
}
