import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_loading_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_result_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_setup_view.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_items_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shows the AI Chef recipe dialog.
@Dependencies([AiChefController, InventoryItemsController])
Future<void> showAiChefDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AiChefDialog(),
  );
}

/// The dialog widget coordinating the AI generation process.
@Dependencies([AiChefController, InventoryItemsController])
class AiChefDialog extends ConsumerStatefulWidget {
  /// Creates a dialog.
  const AiChefDialog({super.key});

  @override
  ConsumerState<AiChefDialog> createState() => _AiChefDialogState();
}

class _AiChefDialogState extends ConsumerState<AiChefDialog> {
  final _wishesController = TextEditingController();
  bool _isSaving = false;
  bool _includeInventory = true;

  @override
  void dispose() {
    _wishesController.dispose();
    super.dispose();
  }

  void _startGeneration() {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
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
    final state = ref.watch(aiChefControllerProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppInsets.dialogInset,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.narrowContentMaxWidth,
        ),
        child: DecoratedBox(
          decoration: AppEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(AppEditorial.cardRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: state.when(
              data: (recipe) {
                if (recipe == null) {
                  return AiChefSetupView(
                    wishesController: _wishesController,
                    includeInventory: _includeInventory,
                    onIncludeInventoryChanged: (value) {
                      setState(() {
                        _includeInventory = value;
                      });
                    },
                    onGenerate: _startGeneration,
                    onClose: context.pop,
                  );
                }
                return AiChefResultView(
                  recipe: recipe,
                  onSave: () => _saveRecipe(recipe),
                  onClose: context.pop,
                  isSaving: _isSaving,
                );
              },
              loading: () => const AiChefLoadingView(),
              error: (error, _) => _ErrorStateView(
                onRetry: _startGeneration,
                onClose: context.pop,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveRecipe(PreparedMeal recipe) async {
    if (_isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    unawaited(HapticFeedback.mediumImpact());
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(
      preparedMealTemplatesControllerProvider.notifier,
    );

    final result = await controller.saveRecipeTemplate(recipe);

    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      _showSnackBar(l10n.aiChefSaveSuccess);
      context.pop();
    } else {
      setState(() {
        _isSaving = false;
      });
      _showSnackBar(l10n.aiChefSaveError);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _ErrorStateView extends StatelessWidget {
  const _ErrorStateView({required this.onRetry, required this.onClose});

  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.preparedMealTemplatesLoadFailed,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClose,
                  child: Text(l10n.aiChefCloseAction),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: onRetry,
                  child: Text(l10n.productSearchHubSearchRetryAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
