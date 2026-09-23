import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/controllers/'
    'kitchen_utensils_controller.dart';
import 'package:yamt/features/kitchen_utensils/presentation/kitchen_utensil_edit_flow.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Kitchen utensils page.
class KitchenUtensilsPage extends ConsumerWidget {
  /// Creates page.
  const new({super.key});

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
            onPressed: () =>
                unawaited(KitchenUtensilEditFlow.add(context, ref)),
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
                onEditPressed: (utensil) =>
                    KitchenUtensilEditFlow.edit(context, ref, utensil),
                onDeletePressed: (_) =>
                    KitchenUtensilEditFlow.delete(context, ref, utensil),
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
}
