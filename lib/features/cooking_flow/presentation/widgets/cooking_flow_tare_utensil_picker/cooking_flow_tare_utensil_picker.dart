import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_quiet_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_tare_utensil_picker/cooking_flow_tare_utensil_list.dart';
import 'package:yamt/features/kitchen_utensils/application/kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Picker for applying saved kitchen utensils as cookflow tare.
class CookingFlowTareUtensilPicker extends ConsumerWidget {
  /// Creates picker.
  const new({
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
    final utensilsAsync = ref.watch(kitchenUtensilListProvider);

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
              return const _CookingFlowTareUtensilEmptyState();
            }
            return CookingFlowTareUtensilList(
              utensils: utensils,
              selectedTaraWeightGrams: selectedTaraWeightGrams,
              selectedUtensilId: selectedUtensilId,
              onSelected: onSelected,
            );
          },
          loading: () => const _CookingFlowTareUtensilLoading(),
          error: (error, stackTrace) => _CookingFlowTareUtensilLoadError(
            onRetryPressed: () => ref.invalidate(kitchenUtensilListProvider),
            message: l10n.cookflowTaraUtensilsLoadFailed,
          ),
        ),
      ],
    );
  }
}

class _CookingFlowTareUtensilHeader extends StatelessWidget {
  const new({required this.title, required this.onOpenKitchenUtensilsPressed});

  final String title;
  final VoidCallback onOpenKitchenUtensilsPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(title.toUpperCase(), style: context.graphitKickerStyle),
        ),
        CookingFlowQuietButton(
          label: l10n.kitchenUtensilAddAction,
          onPressed: onOpenKitchenUtensilsPressed,
        ),
      ],
    );
  }
}

/// Shown without saved utensils. The header above already offers
/// "Utensil hinzufügen", so this is text only.
class _CookingFlowTareUtensilEmptyState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Text(
          l10n.kitchenUtensilsEmptyState,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.muted),
        ),
      ),
    );
  }
}

class _CookingFlowTareUtensilLoading extends StatelessWidget {
  const new();

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
  const new({required this.message, required this.onRetryPressed});

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
