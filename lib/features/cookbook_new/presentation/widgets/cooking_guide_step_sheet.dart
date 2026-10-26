import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Asks which of the recipe's [steps] the Kochhelfer jumps to, with the
/// step [current] marked. Returns its number from 1, or `null` when the
/// cook closes the sheet.
Future<int?> showCookingGuideStepSheet({
  required BuildContext context,
  required List<String> steps,
  required int current,
}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => CookingGuideStepSheet(steps: steps, current: current),
);

/// The recipe's steps to jump to, the one on the screen marked.
class CookingGuideStepSheet extends StatelessWidget {
  /// Creates the sheet.
  const new({required this.steps, required this.current, super.key});

  /// Key of the step [step], from 1.
  static ValueKey<String> stepKey(int step) =>
      ValueKey<String>('cooking-guide-step-$step');

  /// The recipe's steps.
  final List<String> steps;

  /// The step on the screen, from 1.
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(context).height *
              AppGraphit.pickerSheetHeightFactor,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.cookingGuideJumpTitle.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: colors.muted,
                  letterSpacing: AppGraphit.kickerTracking,
                ),
              ),
            ),
            for (final (index, step) in steps.indexed)
              if (step.trim().isNotEmpty)
                ListTile(
                  key: stepKey(index + 1),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  leading: Text(
                    '${index + 1}',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  title: Text(
                    step,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: index + 1 == current ? FontWeight.w700 : null,
                    ),
                  ),
                  trailing: index + 1 == current
                      ? Icon(Icons.check_rounded, color: colors.ink)
                      : null,
                  onTap: () => Navigator.of(context).pop(index + 1),
                ),
          ],
        ),
      ),
    );
  }
}
