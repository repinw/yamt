import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_amount_text.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_item_picker_sheet.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The head of the Vorrat picker: the line [title] and "Welches nimmst
/// du?" with [hint] (hidden while typing), then the search, which reports
/// its text to [onSearch].
class KochmodusPickerHead extends StatelessWidget {
  /// Creates the head of the line [title].
  const new({
    required this.title,
    required this.hint,
    required this.onSearch,
    super.key,
  });

  /// The line as it is cooked, such as "750 g Hack".
  final String title;

  /// The line under the question.
  final String hint;

  /// Called with the search text.
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          // The keyboard leaves room only for the field and the list.
          if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
            Text(
              title.toUpperCase(),
              style: textTheme.labelMedium?.copyWith(
                color: colors.muted,
                letterSpacing: AppGraphit.kickerTracking,
              ),
            ),
            Text(
              l10n.kochmodusPickerTitle,
              style: textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (MediaQuery.viewInsetsOf(context).bottom == 0)
            Text(
              hint,
              style: textTheme.bodySmall?.copyWith(color: colors.muted),
            ),
          TextField(
            key: KochmodusItemPickerSheet.searchKey,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.inventorySearchLabel,
              prefixIcon: const Icon(Icons.search_rounded),
            ),
            onChanged: onSearch,
            onTapUpOutside: (_) => FocusScope.of(context).unfocus(),
          ),
        ],
      ),
    );
  }
}

/// What the cook answered in the foot of the Vorrat picker.
enum KochmodusPickerShort {
  /// "So lassen", or the tapped foods cover the line.
  keep,

  /// "Nur N nehmen": the line takes what the tapped foods hold.
  takeOnly,

  /// "N kaufen": the line takes what the tapped foods hold, and the rest goes
  /// on the shopping list.
  buyRest,
}

/// What the Vorrat picker gives back: the ids of the tapped items in the
/// order they were tapped (none for "Etwas anderes suchen") and what the
/// line does when they hold too little.
typedef KochmodusPickerResult = ({
  List<String> ids,
  KochmodusPickerShort short,
});

/// The foot of the Vorrat picker once a food is tapped. When the tapped foods
/// hold some but less than [need], what is still missing ([missing], in the
/// warning colour) and the two ways on: "Nur N nehmen" and "N kaufen".
/// Else "So lassen", which keeps them as they are.
class KochmodusPickerKeep extends StatelessWidget {
  /// Creates the foot for a line that needs [need].
  const new({
    required this.need,
    required this.missing,
    required this.onAnswer,
    super.key,
  });

  /// What the line needs, `null` without an amount.
  final TemplateIngredientRequirement? need;

  /// What the tapped foods still lack, in the unit of [need].
  final int missing;

  /// Closes the picker with the cook's answer.
  final ValueChanged<KochmodusPickerShort> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final need = this.need;
    final big = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
    );
    if (need == null || missing <= 0 || need.amount - missing <= 0) {
      return FilledButton.tonal(
        key: KochmodusItemPickerSheet.keepKey,
        onPressed: () => onAnswer(KochmodusPickerShort.keep),
        style: big,
        child: Text(l10n.kochmodusPickerKeep),
      );
    }
    String amount(int value) =>
        kochmodusAmountText(l10n, value, need.unit, need.countMeasureLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        Text(
          l10n.kochmodusPickerStillMissing(amount(missing)),
          key: KochmodusItemPickerSheet.missingKey,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: FoodLabelColors.of(context).low,
            fontWeight: FontWeight.w700,
          ),
        ),
        FilledButton(
          key: KochmodusItemPickerSheet.takeOnlyKey,
          onPressed: () => onAnswer(KochmodusPickerShort.takeOnly),
          style: big,
          child: Text(
            l10n.kochmodusAmountTakeOnly(amount(need.amount - missing)),
          ),
        ),
        FilledButton.tonal(
          key: KochmodusItemPickerSheet.buyRestKey,
          onPressed: () => onAnswer(KochmodusPickerShort.buyRest),
          style: big,
          child: Text(l10n.kochmodusAmountBuyRest(amount(missing))),
        ),
      ],
    );
  }
}
