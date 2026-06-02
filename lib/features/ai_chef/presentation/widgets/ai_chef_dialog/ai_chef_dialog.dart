import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/ai_chef/application/'
    'ai_chef_inventory_input_builder.dart';
import 'package:yamt/features/ai_chef/presentation/controllers/'
    'ai_chef_controller.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_loading_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_result_view.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/'
    'ai_chef_dialog/ai_chef_setup_view.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Loads inventory items for AI Chef.
typedef AiChefInventoryItemsLoader = Future<List<InventoryItem>> Function();

/// Shows the AI Chef recipe dialog.
Future<void> showAiChefDialog(
  BuildContext context, {
  AiChefInventoryItemsLoader? inventoryItemsLoader,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AiChefDialog(inventoryItemsLoader: inventoryItemsLoader);
    },
  );
}

/// The dialog widget coordinating the AI generation process.
class AiChefDialog extends ConsumerStatefulWidget {
  /// Creates a dialog.
  const AiChefDialog({super.key, this.inventoryItemsLoader});

  /// Loads active inventory from the caller scope.
  final AiChefInventoryItemsLoader? inventoryItemsLoader;

  @override
  ConsumerState<AiChefDialog> createState() => _AiChefDialogState();
}

class _AiChefDialogState extends ConsumerState<AiChefDialog> {
  static const _inventoryInputBuilder = AiChefInventoryInputBuilder();

  final _wishesController = TextEditingController();
  List<String> _inventoryIngredientNames = const <String>[];
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
    final inventoryIngredientsLoader = _loadInventoryIngredients;
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      ref
          .read(aiChefControllerProvider.notifier)
          .generateRecipe(
            isGerman: l10n.localeName == 'de',
            includeInventory: _includeInventory,
            wishes: _wishesController.text,
            inventoryIngredientsLoader: inventoryIngredientsLoader,
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
                  inventoryIngredients: _inventoryIngredientNames,
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

  Future<List<String>> _loadInventoryIngredients() async {
    _inventoryIngredientNames = const <String>[];
    if (!_includeInventory) {
      return const <String>[];
    }

    final itemsLoader = widget.inventoryItemsLoader;
    if (itemsLoader == null) {
      return const <String>[];
    }

    try {
      final items = await itemsLoader();
      if (!mounted) {
        return const <String>[];
      }
      _inventoryIngredientNames = _inventoryInputBuilder.buildNames(items);
      return _inventoryInputBuilder.build(items);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to load inventory for AI Chef.',
        name: 'AiChefDialog',
        error: error,
        stackTrace: stackTrace,
      );
      return const <String>[];
    }
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

    var shouldResetSaving = true;
    try {
      final result = await controller.saveRecipeTemplate(recipe);
      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        shouldResetSaving = false;
        _showSnackBar(l10n.aiChefSaveSuccess);
        context.pop();
        return;
      }
      _showSnackBar(l10n.aiChefSaveError);
    } on Object catch (error, stackTrace) {
      log(
        'Failed to save AI Chef recipe.',
        name: 'AiChefDialog',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        _showSnackBar(l10n.aiChefSaveError);
      }
    } finally {
      if (mounted && shouldResetSaving) {
        setState(() {
          _isSaving = false;
        });
      }
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
