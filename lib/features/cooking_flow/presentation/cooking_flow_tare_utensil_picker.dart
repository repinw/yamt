import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensil_cover.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensil_image_url_provider.dart';
import 'package:yamt/features/kitchen_utensils/provider/'
    'kitchen_utensils_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Picker for applying saved kitchen utensils as cookflow tare.
class CookingFlowTareUtensilPicker extends ConsumerWidget {
  /// Creates picker.
  const CookingFlowTareUtensilPicker({
    required this.selectedTaraWeightGrams,
    required this.selectedUtensilId,
    required this.onSelected,
    required this.onOpenKitchenUtensilsPressed,
    this.title,
    super.key,
  });

  /// Currently selected tare weight.
  final int selectedTaraWeightGrams;

  /// Currently selected utensil id.
  final String? selectedUtensilId;

  /// Called when user selects utensil.
  final ValueChanged<KitchenUtensil> onSelected;

  /// Opens full kitchen utensil library.
  final VoidCallback onOpenKitchenUtensilsPressed;

  /// Optional section title.
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final utensilsAsync = ref.watch(kitchenUtensilsControllerProvider);
    final controller = ref.read(kitchenUtensilsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CookingFlowTareUtensilHeader(
          title: title ?? l10n.cookflowTaraUtensilsTitle,
          onOpenKitchenUtensilsPressed: onOpenKitchenUtensilsPressed,
        ),
        const SizedBox(height: AppSpacing.md),
        utensilsAsync.when(
          data: (utensils) {
            if (utensils.isEmpty) {
              return _CookingFlowTareUtensilEmptyState(
                onOpenKitchenUtensilsPressed: onOpenKitchenUtensilsPressed,
              );
            }
            return _CookingFlowTareUtensilList(
              utensils: utensils,
              selectedTaraWeightGrams: selectedTaraWeightGrams,
              selectedUtensilId: selectedUtensilId,
              onSelected: onSelected,
            );
          },
          loading: () => const _CookingFlowTareUtensilLoading(),
          error: (error, stackTrace) => _CookingFlowTareUtensilLoadError(
            onRetryPressed: () => unawaited(controller.refresh()),
            message: l10n.cookflowTaraUtensilsLoadFailed,
          ),
        ),
      ],
    );
  }
}

class _CookingFlowTareUtensilHeader extends StatelessWidget {
  const _CookingFlowTareUtensilHeader({
    required this.title,
    required this.onOpenKitchenUtensilsPressed,
  });

  final String title;
  final VoidCallback onOpenKitchenUtensilsPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onOpenKitchenUtensilsPressed,
          icon: const Icon(Icons.kitchen_rounded),
          label: Text(l10n.kitchenUtensilAddAction),
        ),
      ],
    );
  }
}

class _CookingFlowTareUtensilEmptyState extends StatelessWidget {
  const _CookingFlowTareUtensilEmptyState({
    required this.onOpenKitchenUtensilsPressed,
  });

  final VoidCallback onOpenKitchenUtensilsPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: <Widget>[
            Icon(Icons.kitchen_rounded, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                l10n.kitchenUtensilsEmptyState,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            IconButton.filledTonal(
              tooltip: l10n.kitchenUtensilAddAction,
              onPressed: onOpenKitchenUtensilsPressed,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CookingFlowTareUtensilList extends StatelessWidget {
  const _CookingFlowTareUtensilList({
    required this.utensils,
    required this.selectedTaraWeightGrams,
    required this.selectedUtensilId,
    required this.onSelected,
  });

  final List<KitchenUtensil> utensils;
  final int selectedTaraWeightGrams;
  final String? selectedUtensilId;
  final ValueChanged<KitchenUtensil> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: utensils.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final utensil = utensils[index];
        return _CookingFlowTareUtensilTile(
          utensil: utensil,
          isSelected:
              selectedUtensilId == utensil.id ||
              (selectedUtensilId == null &&
                  utensil.weightGrams == selectedTaraWeightGrams),
          onSelected: onSelected,
        );
      },
    );
  }
}

class _CookingFlowTareUtensilTile extends ConsumerWidget {
  const _CookingFlowTareUtensilTile({
    required this.utensil,
    required this.isSelected,
    required this.onSelected,
  });

  final KitchenUtensil utensil;
  final bool isSelected;
  final ValueChanged<KitchenUtensil> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final imagePath = utensil.imageStoragePath;
    final imageUrl = imagePath == null
        ? null
        : ref.watch(kitchenUtensilImageUrlProvider(imagePath)).asData?.value;
    final displayName = utensil.name ?? l10n.kitchenUtensilUnnamedLabel;
    final weightLabel = l10n.kitchenUtensilWeightValue(utensil.weightGrams);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Semantics(
      key: Key('cookflow_tare_utensil_${utensil.id}'),
      button: true,
      selected: isSelected,
      label: '$displayName, $weightLabel',
      child: Material(
        color: isSelected
            ? colors.primaryContainer
            : colors.surfaceContainerLow,
        borderRadius: radius,
        child: AppInkWell(
          borderRadius: radius,
          onTap: () => onSelected(utensil),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                KitchenUtensilCover(
                  label: displayName,
                  imageBytes: null,
                  imageUrl: imageUrl,
                  size: 48,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        weightLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CookingFlowTareUtensilLoading extends StatelessWidget {
  const _CookingFlowTareUtensilLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: AppSizes.inlineProgressIndicator,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStrokeWidth,
        ),
      ),
    );
  }
}

class _CookingFlowTareUtensilLoadError extends StatelessWidget {
  const _CookingFlowTareUtensilLoadError({
    required this.message,
    required this.onRetryPressed,
  });

  final String message;
  final VoidCallback onRetryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: <Widget>[
            Icon(Icons.wifi_tethering_error_rounded, color: colors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
            TextButton(
              onPressed: onRetryPressed,
              child: Text(l10n.inventoryRetryAction),
            ),
          ],
        ),
      ),
    );
  }
}
