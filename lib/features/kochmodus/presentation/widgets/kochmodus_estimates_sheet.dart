import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_actions.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/kochmodus_action_flow.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_step_foot.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_weigh_sheet.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Ansehen": first the lines without any weight under "Noch zu wiegen"
/// (`KochmodusView.unweighed`), then those whose weight we estimated under
/// "Bei N Zutaten haben wir das Gewicht geschätzt" (`KochmodusView.guessed`),
/// with one title when only one kind is there; each line with "Ändern", which
/// opens the keypad. A changed line leaves the list, and the sheet closes
/// once both lists are empty. Weighing is optional,
/// unless a line takes nothing: then the note says it must be weighed.
class KochmodusEstimatesSheet extends ConsumerWidget {
  /// Creates the sheet for the cooking of [target].
  const new({required this.target, super.key});

  /// Key of "Passt so".
  static const doneKey = ValueKey<String>('kochmodus-estimates-done');

  /// Key of "Ändern" of the line [lineId].
  static ValueKey<String> changeKey(String lineId) =>
      ValueKey<String>('kochmodus-estimates-change-$lineId');

  /// What the page cooks.
  final KochmodusTarget target;

  /// Shows the sheet for the cooking of [target].
  static Future<void> show(BuildContext context, KochmodusTarget target) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (_) => KochmodusEstimatesSheet(target: target),
      );

  /// What "Ansehen" lists, in words: "Bei N Zutaten haben wir das Gewicht
  /// geschätzt" while one of [view]'s lines carries an estimated weight, else
  /// "Noch zu wiegen" for the lines whose weight is missing.
  static String titleOf(AppLocalizations l10n, KochmodusView view) =>
      view.estimatedCount > 0
      ? l10n.kochmodusEstimatedIngredients(view.estimatedCount)
      : l10n.kochmodusToWeigh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Once no line is left to show, the sheet closes; not a route over it.
    ref.listen(kochmodusControllerProvider(target), (_, next) {
      final view = next.value;
      if (view != null &&
          view.unweighed.isEmpty &&
          view.guessed.isEmpty &&
          (ModalRoute.of(context)?.isCurrent ?? false)) {
        Navigator.of(context).pop();
      }
    });
    final view = ref.watch(kochmodusControllerProvider(target)).value;
    if (view == null) return const SizedBox.shrink();
    final unweighed = view.unweighed;
    final guessed = view.guessed;
    // A line that takes nothing keeps "In Vorrat" waiting until it is
    // weighed.
    final note = !unweighed.any((line) => line.takesNothing)
        ? l10n.kochmodusEstimatesNote
        : guessed.isEmpty
        ? l10n.kochmodusToWeighNote
        : l10n.kochmodusEstimatesMustWeigh;
    final estimatedTitle = l10n.kochmodusEstimatedIngredients(guessed.length);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    unweighed.isEmpty ? estimatedTitle : l10n.kochmodusToWeigh,
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    note,
                    style: textTheme.bodySmall?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final line in unweighed)
                    _EstimateRow(target: target, line: line),
                  if (unweighed.isNotEmpty && guessed.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        estimatedTitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  for (final line in guessed)
                    _EstimateRow(target: target, line: line),
                ],
              ),
            ),
            FilledButton(
              key: doneKey,
              onPressed: () => Navigator.of(context).pop(),
              style: KochmodusStepFoot.mainButtonStyle(context),
              child: Text(l10n.kochmodusEstimatesDone),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const new({required this.target, required this.line});

  final KochmodusTarget target;
  final KochmodusLineView line;

  int? get _estimate => switch (line.weight) {
    CookWeightEstimated(:final grams) => grams,
    _ => null,
  };

  Future<void> _change(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final grams = await KochmodusWeighSheet.show(
      context,
      title: line.text,
      sub: l10n.kochmodusEstimateSub,
      hint: _estimate,
      estimate: true,
    );
    if (grams == null || !context.mounted) return;
    await KochmodusActionFlow.run(
      context,
      target,
      (controller) => controller.weigh(line.id, grams),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final estimate = _estimate;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.text,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    estimate == null
                        ? l10n.kochmodusWeightMissing
                        : l10n.kochmodusEstimateRow(estimate),
                    style: textTheme.bodySmall?.copyWith(
                      color: estimate == null ? colors.low : colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              key: KochmodusEstimatesSheet.changeKey(line.id),
              onPressed: () => unawaited(_change(context)),
              child: Text(l10n.kochmodusChange),
            ),
          ],
        ),
      ),
    );
  }
}
