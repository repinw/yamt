import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The "In Vorrat" button under the "Gekocht" page.
class CookedMealSaveBar extends StatelessWidget {
  /// Creates the bar; [onSave] is `null` while the meal cannot be saved.
  const new({required this.onSave, super.key});

  /// Key of the button.
  static const saveKey = ValueKey<String>('cooked-save');

  /// Saves the meal, or `null` to turn the button off.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: FilledButton(
        key: saveKey,
        onPressed: onSave,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
        ),
        child: Text(AppLocalizations.of(context)!.cookedSave),
      ),
    );
  }
}
