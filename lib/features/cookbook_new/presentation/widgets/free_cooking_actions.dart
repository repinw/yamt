import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_type_tool.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Bottom of the "Frei kochen" page: "Schreiben" to type rows and the lime
/// "Kochen" button that saves the meal.
class FreeCookingActions extends StatelessWidget {
  /// Creates the actions.
  const new({
    required this.isCooking,
    required this.onType,
    required this.onCook,
    super.key,
  });

  /// Key of the "Schreiben" tool.
  static const typeKey = ValueKey<String>('free-cooking-type');

  /// Key of the "Kochen" button.
  static const cookKey = ValueKey<String>('free-cooking-cook');

  /// Whether "Kochen" is saving the meal.
  final bool isCooking;

  /// Opens the text sheet.
  final VoidCallback onType;

  /// Saves the meal; `null` disables the button.
  final VoidCallback? onCook;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          CookingTypeTool(key: typeKey, onPressed: isCooking ? null : onType),
          Expanded(
            child: FilledButton(
              key: cookKey,
              onPressed: onCook,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accent,
                foregroundColor: colors.onAccent,
                minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
              ),
              child: isCooking
                  ? SizedBox.square(
                      dimension: AppGraphit.toolIcon,
                      child: CircularProgressIndicator(
                        strokeWidth: AppGraphit.highlightUnderline,
                        color: colors.onAccent,
                      ),
                    )
                  : Text(l10n.freeCookingCookAction),
            ),
          ),
        ],
      ),
    );
  }
}
