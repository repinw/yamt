import 'dart:async';
import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_cook_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_overview.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_sentence_section.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_bottom_bar.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/recipe_flow_top_bar.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The Kochhelfer of a recipe, opened over its recipe page: all
/// ingredients and steps first, then one sentence per screen, while the
/// screen stays on. "Fertig gekocht" puts the meal in the pot and goes on
/// to the "Gekocht" step; leaving earlier cooks nothing.
class CookingGuidePage extends ConsumerStatefulWidget {
  /// Creates the Kochhelfer of the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// Key of "Los geht's" on the first screen.
  static const startKey = ValueKey<String>('cooking-guide-start');

  /// Key of "Nächster Satz".
  static const nextKey = ValueKey<String>('cooking-guide-next');

  /// Key of "Fertig gekocht".
  static const doneKey = ValueKey<String>('cooking-guide-done');

  /// Key of the back button at the top.
  static const backKey = ValueKey<String>('cooking-guide-back');

  /// The recipe.
  final String recipeId;

  @override
  ConsumerState<CookingGuidePage> createState() => _CookingGuidePageState();
}

class _CookingGuidePageState extends ConsumerState<CookingGuidePage> {
  late final ScreenWakeLock _wakeLock;

  /// The sentence on the screen, or `null` for the first screen.
  int? _sentence;

  @override
  void initState() {
    super.initState();
    _wakeLock = ref.read(screenWakeLockProvider)..acquire();
  }

  @override
  void dispose() {
    _wakeLock.release();
    super.dispose();
  }

  /// Goes back from the shown [sentence]: one sentence, or to the recipe.
  void _back(int? sentence) {
    if (sentence == null) {
      context.pop();
    } else {
      setState(() => _sentence = sentence == 0 ? null : sentence - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final guideAsync = ref.watch(
      cookingGuideProvider(widget.recipeId, l10n.localeName),
    );
    final isCooking = ref.watch(
      recipeControllerProvider(widget.recipeId).select((d) => d.isCooking),
    );
    final guide = guideAsync.value;
    // A recipe whose steps got shorter shows its last sentence.
    final sentence = switch ((_sentence, guide?.sentences.length)) {
      (final index?, final count?) when count > 0 => min(index, count - 1),
      _ => null,
    };

    // System back goes one sentence back, like the button at the top.
    return PopScope(
      canPop: sentence == null && !isCooking,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isCooking) {
          _back(sentence);
        }
      },
      child: Scaffold(
        backgroundColor: FoodLabelColors.of(context).paper,
        body: SafeArea(
          child: guideAsync.when(
            data: (guide) => guide == null
                ? Center(child: Text(l10n.recipeNotFound))
                : _CookingGuideBody(
                    guide: guide,
                    sentence: sentence,
                    isCooking: isCooking,
                    onBack: () => _back(sentence),
                    onSentence: (index) => setState(() => _sentence = index),
                    onDone: () => unawaited(
                      RecipeCookFlow.cook(
                        context: context,
                        ref: ref,
                        recipeId: widget.recipeId,
                        fromGuide: true,
                      ),
                    ),
                  ),
            error: (_, _) => AppErrorRetryView(
              message: l10n.recipeLoadFailed,
              retryLabel: l10n.inventoryRetryAction,
              onRetry: () => ref
                ..invalidate(cookbookTemplatesProvider)
                ..invalidate(inventoryQuickEatItemsProvider),
            ),
            loading: () => const AppLoadingView(),
          ),
        ),
      ),
    );
  }
}

class _CookingGuideBody extends StatelessWidget {
  const new({
    required this.guide,
    required this.sentence,
    required this.isCooking,
    required this.onBack,
    required this.onSentence,
    required this.onDone,
  });

  final CookingGuide guide;
  final int? sentence;
  final bool isCooking;
  final VoidCallback onBack;
  final ValueChanged<int> onSentence;
  final VoidCallback onDone;

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
          backKey: CookingGuidePage.backKey,
          onBack: isCooking ? null : onBack,
          caption: sentence == null
              ? l10n.cookingGuideTitle
              : l10n.cookingGuideKeepsScreenOn,
          captionIcon: sentence == null ? null : Icons.wb_sunny_outlined,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: sentence == null
                ? CookingGuideOverview(guide: guide)
                : CookingGuideSentenceSection(guide: guide, index: sentence),
          ),
        ),
        if (sentence == null && guide.sentences.isNotEmpty)
          RecipeBottomBar(
            buttonKey: CookingGuidePage.startKey,
            label: l10n.cookingGuideStart,
            onPressed: isCooking ? null : () => onSentence(0),
          )
        else
          RecipeBottomBar(
            buttonKey: isLast
                ? CookingGuidePage.doneKey
                : CookingGuidePage.nextKey,
            label: isLast ? l10n.cookingGuideDone : l10n.cookingGuideNext,
            onPressed: isLast || isCooking
                ? done
                : () => onSentence(sentence! + 1),
            secondaryKey: CookingGuidePage.doneKey,
            secondaryLabel: isLast ? null : l10n.cookingGuideDone,
            onSecondary: done,
          ),
      ],
    );
  }
}
