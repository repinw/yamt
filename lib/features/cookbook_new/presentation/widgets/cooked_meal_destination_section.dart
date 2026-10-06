import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Where the cooked meal goes after the "Gekocht" step.
enum CookedMealDestination {
  /// One portion goes to the diary now; the rest stays in the Vorrat.
  diary,

  /// The whole meal goes to the Vorrat.
  stock,
}

/// The "Wie geht's weiter" part of the "Gekocht" step: a switch between
/// eating a portion now and putting the meal in the Vorrat.
class CookedMealDestinationSection extends StatelessWidget {
  /// Creates the section with the [selected] destination.
  const new({
    required this.selected,
    required this.canEat,
    required this.onChanged,
    super.key,
  });

  /// Key of the segment for [destination].
  static ValueKey<String> segmentKey(CookedMealDestination destination) =>
      ValueKey<String>('cooked-destination-${destination.name}');

  /// The picked destination.
  final CookedMealDestination selected;

  /// Whether the meal can be eaten now; a meal with open rows cannot.
  final bool canEat;

  /// Picks the destination.
  final ValueChanged<CookedMealDestination> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        CookbookSectionTitle(title: l10n.cookedNextTitle),
        SegmentedButton<CookedMealDestination>(
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: [
            for (final (value, label) in [
              (CookedMealDestination.diary, l10n.cookedToDiary),
              (CookedMealDestination.stock, l10n.cookedSave),
            ])
              ButtonSegment(
                value: value,
                enabled: canEat || value == CookedMealDestination.stock,
                // Large text shrinks the word instead of breaking it.
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, key: segmentKey(value)),
                ),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (selection) => onChanged(selection.single),
        ),
        if (selected == CookedMealDestination.diary)
          Text(
            l10n.cookedToDiaryNote,
            style: textTheme.bodyMedium?.copyWith(color: colors.muted),
          ),
      ],
    );
  }
}
