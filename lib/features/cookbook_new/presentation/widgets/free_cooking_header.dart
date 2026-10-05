import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cookbook_section_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Top of the "Frei kochen" page: close button, page kicker, the name of
/// the dish, and the ingredient title with how many foods the Vorrat holds.
class FreeCookingHeader extends StatelessWidget {
  /// Creates the header.
  const new({required this.nameController, required this.rows, super.key});

  /// Key of the name field.
  static const nameKey = ValueKey<String>('free-cooking-name');

  /// Key of the close button.
  static const closeKey = ValueKey<String>('free-cooking-close');

  /// Holds the typed name of the dish.
  final TextEditingController nameController;

  /// The ingredient rows.
  final List<FreeCookingRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: closeKey,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.close_rounded, color: colors.ink),
              ),
              Flexible(
                child: Text(
                  l10n.cookbookFreeCookingAction.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: AppGraphit.kickerTracking,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                TextField(
                  key: nameKey,
                  controller: nameController,
                  textCapitalization: TextCapitalization.sentences,
                  // Otherwise the name takes the focus back when the typing
                  // sheet closes, and the keyboard opens again.
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  style: textTheme.headlineSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.freeCookingNameHint,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: colors.rule),
                    ),
                  ),
                ),
                CookbookSectionTitle(
                  title: l10n.freeCookingIngredientsTitle,
                  caption: rows.isEmpty
                      ? null
                      : l10n.freeCookingStockCount(
                          rows.inStockCount,
                          rows.length,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
