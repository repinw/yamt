import 'dart:async';
import 'dart:math' show min;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cooking_guide_view.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/recipe_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_cook_flow.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_guide_body.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cooking_voice_input_mixin.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The Kochhelfer of a recipe, opened over its recipe page: all
/// ingredients and steps first, then one sentence per screen, while the
/// screen stays on. On a sentence the cook can say or type what else goes
/// into the pot this time, and "nein" takes it back. "Fertig gekocht" puts
/// the meal in the pot and goes on to the "Gekocht" step; leaving earlier
/// cooks nothing.
class CookingGuidePage extends ConsumerStatefulWidget {
  /// Creates the Kochhelfer of the recipe [recipeId].
  const new({required this.recipeId, super.key});

  /// The recipe.
  final String recipeId;

  @override
  ConsumerState<CookingGuidePage> createState() => _CookingGuidePageState();
}

class _CookingGuidePageState extends ConsumerState<CookingGuidePage>
    with
        VoiceInputStateMixin<CookingGuidePage>,
        CookingVoiceInputMixin<CookingGuidePage> {
  @override
  late final VoiceSearchService voiceService;
  late final ScreenWakeLock _wakeLock;

  /// The sentence on the screen, or `null` for the first screen.
  int? _sentence;

  /// Whether "Fertig gekocht" is on its way to the pot.
  bool _isFinishing = false;

  RecipeControllerProvider get _recipe =>
      recipeControllerProvider(widget.recipeId);

  @override
  void initState() {
    super.initState();
    voiceService = ref.read(voiceSearchServiceProvider);
    _wakeLock = ref.read(screenWakeLockProvider)..acquire();
  }

  @override
  void dispose() {
    cancelListening();
    _wakeLock.release();
    super.dispose();
  }

  @override
  bool get pausesVoiceInput => _isFinishing || ref.read(_recipe).isCooking;

  @override
  void onSpokenText(String text) {
    final localeCode = AppLocalizations.of(context)!.localeName;
    final view = ref.read(recipeViewProvider(widget.recipeId, localeCode));
    if (view.value case final view?) {
      ref.read(_recipe.notifier).addSpoken(view, text);
    }
  }

  Future<void> _done() async {
    setState(() => _isFinishing = true);
    // What the cook is still saying goes into the pot too.
    await finishListening();
    if (!mounted) {
      return;
    }
    await RecipeCookFlow.cook(
      context: context,
      ref: ref,
      recipeId: widget.recipeId,
      fromGuide: true,
    );
    if (mounted) {
      setState(() => _isFinishing = false);
    }
  }

  /// Goes back from the shown [sentence]: one sentence, or to the recipe.
  void _back(int? sentence) {
    if (sentence == null) {
      context.pop();
      return;
    }
    if (sentence == 0) {
      // The overview has no voice zone to stop listening with.
      unawaited(stopListening());
    }
    setState(() => _sentence = sentence == 0 ? null : sentence - 1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final guideAsync = ref.watch(
      cookingGuideProvider(widget.recipeId, l10n.localeName),
    );
    final isCooking =
        ref.watch(_recipe.select((d) => d.isCooking)) || _isFinishing;
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
                : CookingGuideBody(
                    guide: guide,
                    sentence: sentence,
                    isCooking: isCooking,
                    isListening: isListening,
                    pendingSpeech: pendingSpeech,
                    onBack: () => _back(sentence),
                    onSentence: (index) => setState(() => _sentence = index),
                    onDone: () => unawaited(_done()),
                    onVoice: () => unawaited(toggleListening()),
                    onType: () => unawaited(typeText()),
                    onUndo: () => ref.read(_recipe.notifier).undoAdded(),
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
