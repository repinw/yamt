import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/inventory/data/prepared_meal_image_picker.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/domain/'
    'kitchen_utensil_save_result.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_card.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_sheet.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensils_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kitchen utensils page.
@Dependencies([preparedMealImagePicker])
class KitchenUtensilsPage extends ConsumerWidget {
  /// Creates page.
  const KitchenUtensilsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(kitchenUtensilsControllerProvider, _logLoadErrorOnce);

    final l10n = AppLocalizations.of(context)!;
    final utensilsController = ref.read(
      kitchenUtensilsControllerProvider.notifier,
    );
    final utensilsAsync = ref.watch(kitchenUtensilsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.kitchenUtensilsPageTitle),
        actions: [
          IconButton(
            tooltip: l10n.kitchenUtensilAddAction,
            onPressed: () => unawaited(_addUtensil(context: context, ref: ref)),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: utensilsAsync.when(
        data: (utensils) {
          if (utensils.isEmpty) {
            return Center(
              child: Padding(
                padding: AppInsets.pageLarge,
                child: Text(
                  l10n.kitchenUtensilsEmptyState,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            itemCount: utensils.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) {
              final utensil = utensils[index];
              return KitchenUtensilCard(
                utensil: utensil,
                onEditPressed: (utensil) => _editUtensil(
                  context: context,
                  ref: ref,
                  utensil: utensil,
                ),
                onDeletePressed: (utensilId) => _deleteUtensil(
                  context: context,
                  ref: ref,
                  utensilId: utensilId,
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: SizedBox.square(
            dimension: AppSizes.inlineProgressIndicator,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.progressStrokeWidth,
            ),
          ),
        ),
        error: (error, stackTrace) {
          return Center(
            child: Padding(
              padding: AppInsets.pageLarge,
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: AppInsets.card,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.wifi_tethering_error_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.kitchenUtensilsLoadFailed,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: utensilsController.refresh,
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.inventoryRetryAction),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _logLoadErrorOnce(
    AsyncValue<List<KitchenUtensil>>? previous,
    AsyncValue<List<KitchenUtensil>> next,
  ) {
    final nextError = next.asError;
    if (nextError == null) {
      return;
    }

    final previousError = previous?.asError;
    final unchangedError = identical(previousError?.error, nextError.error);
    final unchangedStack = previousError?.stackTrace == nextError.stackTrace;
    if (unchangedError && unchangedStack) {
      return;
    }

    developer.log(
      'Failed to load kitchen utensils.',
      name: 'KitchenUtensilsPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  Future<bool> _addUtensil({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final controller = ref.read(kitchenUtensilsControllerProvider.notifier);
    final draft = await showKitchenUtensilSheet(context: context);
    if (!context.mounted || draft == null) {
      return false;
    }

    final result = await controller.addUtensil(
      name: draft.name,
      imageBytes: draft.imageBytes,
      weightGrams: draft.weightGrams,
    );
    if (!context.mounted) {
      return result.isSuccess;
    }

    if (result.isSuccess) {
      _showSnackBar(
        context,
        AppLocalizations.of(context)!.kitchenUtensilSavedMessage,
      );
      return true;
    }

    _showSnackBar(
      context,
      _saveFailureMessage(AppLocalizations.of(context)!, result),
    );
    return false;
  }

  Future<bool> _editUtensil({
    required BuildContext context,
    required WidgetRef ref,
    required KitchenUtensil utensil,
  }) async {
    final controller = ref.read(kitchenUtensilsControllerProvider.notifier);
    final draft = await showKitchenUtensilSheet(
      context: context,
      initialUtensil: utensil,
    );
    if (!context.mounted || draft == null) {
      return false;
    }

    final result = await controller.updateUtensil(
      utensilId: utensil.id,
      name: draft.name,
      imageBytes: draft.imageBytes,
      imageChanged: draft.imageChanged,
      weightGrams: draft.weightGrams,
    );
    if (!context.mounted) {
      return result.isSuccess;
    }

    if (result.isSuccess) {
      _showSnackBar(
        context,
        AppLocalizations.of(context)!.kitchenUtensilUpdatedMessage,
      );
      return true;
    }

    _showSnackBar(
      context,
      _saveFailureMessage(AppLocalizations.of(context)!, result),
    );
    return false;
  }

  Future<bool> _deleteUtensil({
    required BuildContext context,
    required WidgetRef ref,
    required String utensilId,
  }) async {
    final deleted = await ref
        .read(kitchenUtensilsControllerProvider.notifier)
        .deleteUtensil(utensilId);
    if (!context.mounted) {
      return deleted;
    }
    final l10n = AppLocalizations.of(context)!;
    if (!deleted) {
      _showSnackBar(context, l10n.kitchenUtensilDeleteFailed);
      return false;
    }

    _showSnackBar(context, l10n.kitchenUtensilDeletedMessage);
    return true;
  }

  String _saveFailureMessage(
    AppLocalizations l10n,
    KitchenUtensilSaveResult result,
  ) {
    return switch (result.failureReason) {
      KitchenUtensilSaveFailureReason.invalidInput =>
        l10n.kitchenUtensilIdentityRequired,
      KitchenUtensilSaveFailureReason.imageUploadFailed =>
        l10n.kitchenUtensilImageUploadFailed,
      KitchenUtensilSaveFailureReason.saveFailed ||
      null => l10n.kitchenUtensilSaveFailed,
    };
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
