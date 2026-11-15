import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/ai_chef/data/ai_chef_repository.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/ai_chef_sheet/'
    'ai_chef_loading_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/ai_chef_sheet/'
    'ai_chef_setup_view.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The recipe idea's start: "Worauf hast du Lust?", then "Wir stellen ein
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
  final _wishesController = TextEditingController();
  bool _includeInventory = true;

  @override
  void dispose() {
    _wishesController.dispose();
    super.dispose();
  }

  void _generate() {
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      ref
          .read(aiChefControllerProvider.notifier)
          .generateRecipe(
            isGerman: l10n.localeName == 'de',
            includeInventory: _includeInventory,
            wishes: _wishesController.text,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(aiChefControllerProvider, (_, next) {
      if (next case AsyncData(value: final idea?)) {
        Navigator.of(context).pop(idea);
      }
    });
    final state = ref.watch(aiChefControllerProvider);

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
                  wishesController: _wishesController,
                  includeInventory: _includeInventory,
                  onIncludeInventoryChanged: (value) =>
                      setState(() => _includeInventory = value),
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
