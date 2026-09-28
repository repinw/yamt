import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/kitchen_utensils/application/kitchen_utensil_image_url_provider.dart';
import 'package:yamt/features/kitchen_utensils/domain/kitchen_utensil.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/kitchen_utensil_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Saved utensils as selectable tiles.
class CookingFlowTareUtensilList extends StatelessWidget {
  /// Creates the list.
  const new({
    required this.utensils,
    required this.selectedTaraWeightGrams,
    required this.selectedUtensilId,
    required this.onSelected,
    super.key,
  });

  /// Saved utensils.
  final List<KitchenUtensil> utensils;

  /// Current tare weight.
  final int selectedTaraWeightGrams;

  /// Selected utensil id, if any.
  final String? selectedUtensilId;

  /// Called with the tapped utensil.
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
  const new({
    required this.utensil,
    required this.isSelected,
    required this.onSelected,
  });

  final KitchenUtensil utensil;
  final bool isSelected;
  final ValueChanged<KitchenUtensil> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final foreground = isSelected ? colors.paper : colors.ink;
    final l10n = AppLocalizations.of(context)!;
    final imagePath = utensil.imageStoragePath;
    final imageUrl = imagePath == null
        ? null
        : ref.watch(kitchenUtensilImageUrlProvider(imagePath)).asData?.value;
    final displayName = utensil.name ?? l10n.kitchenUtensilUnnamedLabel;
    final weightLabel = l10n.kitchenUtensilWeightValue(utensil.weightGrams);
    final radius = BorderRadius.circular(AppRadius.md);

    return Semantics(
      key: Key('cookflow_tare_utensil_${utensil.id}'),
      button: true,
      selected: isSelected,
      label: '$displayName, $weightLabel',
      child: Material(
        color: isSelected ? colors.ink : colors.tile,
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
                        style: textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        weightLabel,
                        style: textTheme.bodyMedium?.copyWith(
                          color: isSelected ? colors.paper : colors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) Icon(Icons.check_rounded, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
