import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/ai_chef_must_use_flow.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_exclusions_controller.dart';
import 'package:yamt/features/ai_chef/presentation/models/'
    'ai_chef_setup_draft.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/ai_chef_sheet/'
    'ai_chef_loading_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/ai_chef_sheet/'
    'ai_chef_setup_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The recipe idea's start: the three setup rows, then "Wir stellen ein
/// Rezept zusammen …" while the idea comes. Pops with the idea as soon as
/// its text is there; its picture comes later. Closing the sheet drops the
/// idea.
class AiChefSheet extends ConsumerStatefulWidget {
  /// Creates the sheet.
  const new({super.key});

  /// Key of "Erneut versuchen" after a failed idea.
  static const retryKey = ValueKey<String>('ai-chef-retry');

  /// Shows the sheet and returns the recipe idea, or `null` when the cook
  /// closes it first.
  static Future<AiChefRecipeIdea?> show(BuildContext context) {
    unawaited(HapticFeedback.lightImpact());
    return showModalBottomSheet<AiChefRecipeIdea>(
      context: context,
      // Above the bottom navigation of the home tabs.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const AiChefSheet(),
    );
  }

  @override
  ConsumerState<AiChefSheet> createState() => _AiChefSheetState();
}

class _AiChefSheetState extends ConsumerState<AiChefSheet> {
  var _draft = const AiChefSetupDraft();
  Future<bool>? _pendingExclusionChange;
  bool _exclusionSaveFailed = false;
  bool _isGenerating = false;
  bool _isPicking = false;
  bool _mustUseFailed = false;

  Future<void> _generate() async {
    if (_isGenerating ||
        _isPicking ||
        ref.read(aiChefControllerProvider).isLoading) {
      return;
    }
    _isGenerating = true;
    try {
      await _sendRequest();
    } finally {
      _isGenerating = false;
    }
  }

  Future<void> _sendRequest() async {
    // Leaving an open pill input adds what was typed; the focus change runs
    // in a microtask, this one after it. Then wait for a pending "Bloß
    // nicht" save, so the request carries everything. A failed save stays
    // on the setup with its error: the cook decides whether to go on.
    FocusScope.of(context).unfocus();
    await Future<void>.microtask(() {});
    final pending = _pendingExclusionChange;
    if (pending != null && !await pending) {
      return;
    }
    if (!mounted) {
      return;
    }
    final exclusions = ref.read(aiChefExclusionsControllerProvider).value;
    if (exclusions == null) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    unawaited(HapticFeedback.lightImpact());
    // Sets the loading state before it returns, so the setup is gone before
    // a second tap or a pick could start.
    unawaited(
      ref
          .read(aiChefControllerProvider.notifier)
          .generateRecipe(
            isGerman: l10n.localeName == 'de',
            includeInventory: _draft.includeInventory,
            wishes: _draft.wishes.join(', '),
            excludedIngredients: exclusions.ingredients,
            mustUseIds: {for (final item in _draft.mustUseItems) item.id},
          ),
    );
  }

  Future<void> _changeExclusions(
    Future<bool> Function(AiChefExclusionsController controller) change,
  ) async {
    final saved = change(ref.read(aiChefExclusionsControllerProvider.notifier));
    _pendingExclusionChange = saved;
    final ok = await saved;
    if (identical(_pendingExclusionChange, saved)) {
      _pendingExclusionChange = null;
    }
    if (mounted) {
      setState(() => _exclusionSaveFailed = !ok);
    }
  }

  Future<void> _pickMustUse() async {
    if (_isPicking || _isGenerating) {
      return;
    }
    _isPicking = true;
    final controller = ref.read(aiChefControllerProvider.notifier);
    try {
      final picked = await pickAiChefMustUseItems(
        context,
        loadItems: controller.loadPickableItems,
        picked: _draft.mustUseItems,
        today: ref.read(clockProvider)(),
      );
      if (mounted) {
        setState(() {
          _mustUseFailed = false;
          if (picked != null) _draft = _draft.withMustUse(picked);
        });
      }
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load the Vorrat for "Unbedingt rein".',
        name: 'AiChefSheet',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _mustUseFailed = true);
    } finally {
      _isPicking = false;
    }
  }

  void _changeDraft(AiChefSetupDraft next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    ref.listen(aiChefControllerProvider, (_, next) {
      if (next case AsyncData(value: final idea?)) {
        Navigator.of(context).pop(idea);
      }
    });
    final state = ref.watch(aiChefControllerProvider);
    final exclusions = ref.watch(aiChefExclusionsControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final exclusionsLoadFailed = exclusions.hasError && !exclusions.hasValue;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: state.when(
          // An idea pops the sheet; until then it keeps the loading view.
          data: (idea) => idea != null
              ? const AiChefLoadingView()
              : AiChefSetupView(
                  includeInventory: _draft.includeInventory,
                  onIncludeInventoryChanged: (value) =>
                      _changeDraft(_draft.withInventory(value: value)),
                  mustUseItems: _draft.mustUseItems,
                  onPickMustUse: _pickMustUse,
                  onRemoveMustUse: (id) =>
                      _changeDraft(_draft.withoutMustUse(id)),
                  mustUseError: _mustUseFailed
                      ? l10n.aiChefMustUseLoadError
                      : null,
                  wishes: _draft.wishes,
                  onAddWish: (wish) => _changeDraft(_draft.withWish(wish)),
                  onRemoveWish: (wish) =>
                      _changeDraft(_draft.withoutWish(wish)),
                  excludedIngredients: exclusions.value?.ingredients,
                  exclusionsError: exclusionsLoadFailed
                      ? l10n.aiChefExclusionsLoadError
                      : _exclusionSaveFailed
                      ? l10n.aiChefExclusionsSaveError
                      : null,
                  onRetryExclusions: exclusionsLoadFailed
                      ? () => ref.invalidate(aiChefExclusionsControllerProvider)
                      : null,
                  onAddExclusion: (ingredient) => _changeExclusions(
                    (controller) => controller.addIngredient(ingredient),
                  ),
                  onRemoveExclusion: (ingredient) => _changeExclusions(
                    (controller) => controller.removeIngredient(ingredient),
                  ),
                  onGenerate: _generate,
                ),
          loading: () => const AiChefLoadingView(),
          error: (_, _) => _FailedView(onRetry: _generate),
        ),
      ),
    );
  }
}

class _FailedView extends StatelessWidget {
  const new({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xl,
      children: [
        Text(
          l10n.aiChefIdeaFailed,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: colors.ink, fontWeight: FontWeight.w700),
        ),
        FilledButton(
          key: AiChefSheet.retryKey,
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
          ),
          child: Text(l10n.inventoryRetryAction),
        ),
      ],
    );
  }
}
