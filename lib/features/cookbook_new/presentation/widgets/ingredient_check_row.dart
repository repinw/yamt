import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/ingredient_check_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Sets the choice for an ingredient, or for its missing part when [rest].
typedef IngredientCheckChoose = void Function(
  String ingredient,
  IngredientCheckChoice choice, {
  bool rest,
});

/// One row of the ingredient check: [lead], the amount and the food, a
/// [note], and one button per choice in [options]. The selected choice is
/// filled. "Hab ich" is a text button that calls [onHave].
class IngredientCheckRow extends StatelessWidget {
  /// Creates the row; [id] names its keys.
  const new({
    required this.id,
    required this.lead,
    required this.food,
    required this.choice,
    required this.options,
    required this.onChoose,
    this.amount,
    this.note,
    this.onHave,
    this.onTap,
    super.key,
  });

  /// Key of the button for [choice] in the row [id].
  static ValueKey<String> choiceKey(String id, IngredientCheckChoice choice) =>
      ValueKey<String>('ingredient-check-$id-${choice.name}');

  /// Names the keys of the row.
  final String id;

  /// The Vorrat photo or the stock square.
  final Widget lead;

  /// The amount, such as "600 g".
  final String? amount;

  /// The food.
  final String food;

  /// A line under the food, such as how much is there.
  final String? note;

  /// The selected choice.
  final IngredientCheckChoice choice;

  /// The choices the row offers, in order.
  final List<IngredientCheckChoice> options;

  /// Called with the choice the cook taps.
  final ValueChanged<IngredientCheckChoice> onChoose;

  /// Starts "Hab ich".
  final VoidCallback? onHave;

  /// Opens the Vorrat picker.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final amount = this.amount;
    final note = this.note;

    ButtonStyle style({required bool selected}) => IconButton.styleFrom(
      backgroundColor: selected ? colors.ink : colors.card,
      foregroundColor: selected ? colors.paper : colors.muted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );

    Widget button(IngredientCheckChoice option) {
      final selected = option == choice;
      final key = choiceKey(id, option);
      if (option == IngredientCheckChoice.have) {
        return TextButton(
          key: key,
          onPressed: onHave,
          style: TextButton.styleFrom(
            backgroundColor: selected ? colors.ink : colors.card,
            foregroundColor: selected ? colors.paper : colors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: Text(l10n.recipeCheckHave),
        );
      }
      final (icon, tooltip) = switch (option) {
        IngredientCheckChoice.use => (Icons.check_rounded, l10n.recipeCheckUse),
        IngredientCheckChoice.cart => (
          Icons.shopping_cart_outlined,
          l10n.recipeCheckCart,
        ),
        _ => (Icons.block_rounded, l10n.recipeCheckIgnore),
      };
      return IconButton(
        key: key,
        tooltip: tooltip,
        isSelected: selected,
        style: style(selected: selected),
        onPressed: () => onChoose(option),
        icon: Icon(icon),
      );
    }

    return AppInkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              lead,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          if (amount != null)
                            TextSpan(
                              text: '$amount ',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          TextSpan(text: food),
                        ],
                      ),
                      style: textTheme.bodyLarge?.copyWith(color: colors.ink),
                    ),
                    if (note != null)
                      Text(
                        note,
                        style: textTheme.bodySmall?.copyWith(color: colors.low),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xs,
                children: [for (final option in options) button(option)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
