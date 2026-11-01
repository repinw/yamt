import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The back button and the steps of the whole cooking: Rezept, Einkauf,
/// Kochen, Portionieren, with the current one marked.
class CookTopBar extends StatelessWidget {
  /// Creates the bar at [step].
  const new({required this.step, required this.onBack, super.key});

  /// Key of the back button.
  static const backKey = ValueKey<String>('cook-back');

  /// The step the cook is on.
  final CookStep step;

  /// Goes one step back, or closes the page on the first; `null` while
  /// busy.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final current = switch (step) {
      CookStep.recipe => 0,
      CookStep.found || CookStep.open => 1,
      CookStep.pot => 2,
      CookStep.portion => 3,
    };
    final names = [
      l10n.cookStepRecipe,
      l10n.cookStepShopping,
      l10n.cookStepCooking,
      l10n.cookStepPortion,
    ];
    final closes = step == CookStep.recipe;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            key: backKey,
            tooltip: closes
                ? materialL10n.closeButtonTooltip
                : materialL10n.backButtonTooltip,
            onPressed: onBack,
            icon: closes
                ? const Icon(Icons.close_rounded)
                : const BackButtonIcon(),
          ),
          for (final (index, name) in names.indexed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppGraphit.progressSegmentGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xxs,
                  children: [
                    SizedBox(
                      height: AppGraphit.progressSegmentHeight,
                      width: double.infinity,
                      child: ColoredBox(
                        color: index <= current ? colors.ink : colors.track,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: index == current ? colors.ink : colors.muted,
                        fontWeight: index == current
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
