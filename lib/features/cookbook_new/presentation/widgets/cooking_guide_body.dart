import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_just_added.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_pot_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_sentence_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_type_tool.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_voice_zone.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_bottom_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_flow_top_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What the Kochhelfer shows: the overview, or one sentence with what goes
/// into the pot and the voice zone to add more.
class CookingGuideBody extends StatelessWidget {
  /// Creates the body for [guide] at [sentence].
  const new({
    required this.guide,
    required this.sentence,
    required this.isCooking,
    required this.isListening,
    required this.onBack,
    required this.onSentence,
    required this.onDone,
    required this.onVoice,
    required this.onType,
    required this.onUndo,
    this.pendingSpeech,
    super.key,
  });

  /// Key of "Los geht's" on the first screen.
  static const startKey = ValueKey<String>('cooking-guide-start');

  /// Key of "Nächster Satz".
  static const nextKey = ValueKey<String>('cooking-guide-next');

  /// Key of "Fertig gekocht".
  static const doneKey = ValueKey<String>('cooking-guide-done');

  /// Key of the back button at the top.
  static const backKey = ValueKey<String>('cooking-guide-back');

  /// Key of the voice zone.
  static const voiceKey = ValueKey<String>('cooking-guide-voice');

  /// Key of "Schreiben".
  static const typeKey = ValueKey<String>('cooking-guide-type');

  /// The recipe as the Kochhelfer reads it.
  final CookingGuide guide;

  /// The sentence on the screen, or `null` for the overview.
  final int? sentence;

  /// Whether the meal is going into the pot.
  final bool isCooking;

  /// Whether the microphone is listening.
  final bool isListening;

  /// What the microphone hears before it is final.
  final String? pendingSpeech;

  /// Goes one sentence back, or back to the recipe.
  final VoidCallback onBack;

  /// Shows the sentence at the given index.
  final ValueChanged<int> onSentence;

  /// Puts the meal in the pot.
  final VoidCallback onDone;

  /// Starts or stops listening.
  final VoidCallback onVoice;

  /// Opens the field to type ingredients.
  final VoidCallback onType;

  /// Takes the ingredients added last out again.
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sentence = this.sentence;
    final isLast =
        guide.sentences.isEmpty || sentence == guide.sentences.length - 1;
    final done = isCooking ? null : onDone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecipeFlowTopBar(
          backKey: backKey,
          onBack: isCooking ? null : onBack,
          caption: sentence == null
              ? l10n.cookingGuideTitle
              : l10n.cookingGuideKeepsScreenOn,
          captionIcon: sentence == null ? null : Icons.wb_sunny_outlined,
        ),
        Expanded(
          child: sentence == null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: CookingGuideOverview(guide: guide),
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: AppSpacing.lg,
                        children: [
                          CookingGuideSentenceSection(
                            guide: guide,
                            index: sentence,
                          ),
                          CookingGuidePotSection(
                            ingredients: guide.ingredients,
                          ),
                        ],
                      ),
                    ),
                    // Right above the buttons, within reach, while there is
                    // room; with large text it scrolls with the sentence.
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CookingGuideJustAdded(
                              justAdded: guide.justAdded,
                              pending: pendingSpeech,
                              onUndo: isCooking ? null : onUndo,
                            ),
                            CookingVoiceZone(
                              key: voiceKey,
                              isListening: isListening,
                              onPressed: isCooking ? null : onVoice,
                              idleHint: l10n.cookingGuideVoiceHint,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: CookingTypeTool(
                                key: typeKey,
                                onPressed: isCooking ? null : onType,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (sentence == null && guide.sentences.isNotEmpty)
          RecipeBottomBar(
            buttonKey: startKey,
            label: l10n.cookingGuideStart,
            onPressed: isCooking ? null : () => onSentence(0),
          )
        else
          RecipeBottomBar(
            buttonKey: isLast ? doneKey : nextKey,
            label: isLast ? l10n.cookingGuideDone : l10n.cookingGuideNext,
            onPressed: isLast || isCooking
                ? done
                : () => onSentence(sentence! + 1),
            secondaryKey: doneKey,
            secondaryLabel: isLast ? null : l10n.cookingGuideDone,
            onSecondary: done,
          ),
      ],
    );
  }
}
