import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_chips.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_step_sheet.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/ingredient_check_title.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One sentence of the Kochhelfer: where it is, the sentence in large
/// type, and the ingredients it names. A tap on where it is, or on the
/// bar, offers every step to jump to.
class CookingGuideSentenceSection extends StatelessWidget {
  /// Creates the sentence at [index] of [guide].
  const new({
    required this.guide,
    required this.index,
    required this.onSentence,
    super.key,
  });

  /// Key of the kicker that offers the steps.
  static const jumpKey = ValueKey<String>('cooking-guide-jump');

  /// The recipe as the Kochhelfer reads it.
  final CookingGuide guide;

  /// The sentence to show, from 0.
  final int index;

  /// Shows the sentence at the given index; `null` turns jumping off.
  final ValueChanged<int>? onSentence;

  Future<void> _jump(BuildContext context, int current) async {
    final step = await showCookingGuideStepSheet(
      context: context,
      steps: guide.steps,
      current: current,
    );
    if (step == null || !context.mounted) {
      return;
    }
    // The section as it is now: the recipe or the cooking state may have
    // changed while the sheet was open.
    final section = context.widget as CookingGuideSentenceSection;
    final target = section.guide.sentences.indexWhere(
      (s) => s.sentence.step == step,
    );
    if (target >= 0) {
      section.onSentence?.call(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (:sentence, :ingredients) = guide.sentences[index];
    final jump = onSentence == null
        ? null
        : () => unawaited(_jump(context, sentence.step));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IngredientCheckTitle(
          kicker: l10n.cookingGuideProgress(
            index + 1,
            guide.sentences.length,
            sentence.step,
          ),
          title: sentence.text,
          onKicker: jump,
          kickerKey: jumpKey,
        ),
        // The kicker above reads the same progress out.
        ExcludeSemantics(
          child: AppInkWell(
            onTap: jump,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: _StepBar(guide: guide, index: index),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CookingGuideChips(ingredients: ingredients),
      ],
    );
  }
}

/// The progress through the recipe, one segment per step with sentences:
/// done steps full, the step on the screen by its sentences done, the rest
/// empty.
class _StepBar extends StatelessWidget {
  const new({required this.guide, required this.index});

  final CookingGuide guide;

  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final sentences = guide.sentences;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        spacing: AppGraphit.progressSegmentGap,
        children: [
          for (var step = 1; step <= guide.steps.length; step++)
            if (sentences.any((s) => s.sentence.step == step))
              Expanded(
                child: LinearProgressIndicator(
                  value: _done(sentences, step),
                  minHeight: AppGraphit.progressSegmentHeight,
                  color: colors.ink,
                  backgroundColor: colors.track,
                ),
              ),
        ],
      ),
    );
  }

  double _done(List<CookingGuideSentence> sentences, int step) {
    var count = 0;
    var done = 0;
    for (final (i, s) in sentences.indexed) {
      if (s.sentence.step == step) {
        count++;
        if (i <= index) {
          done++;
        }
      }
    }
    return done / count;
  }
}
