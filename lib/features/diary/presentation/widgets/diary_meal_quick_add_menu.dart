import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/meal_type_l10n.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Compact add menu for a diary meal category.
class DiaryMealQuickAddMenu extends StatelessWidget {
  /// Creates quick add menu.
  const DiaryMealQuickAddMenu({
    required this.mealType,
    required this.onSelected,
    super.key,
  });

  /// Meal type for tooltip/key.
  final MealType mealType;

  /// Source selected by user.
  final ValueChanged<DiaryQuickEatSource> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return PopupMenuButton<DiaryQuickEatSource>(
      key: Key('diary_quick_add_button_${mealType.jsonValue}'),
      tooltip: l10n.diaryQuickEatAddTooltip(mealType.localizedName(l10n)),
      icon: Icon(Icons.add_rounded, color: colors.primary),
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (context) {
        return [
          _item(
            value: DiaryQuickEatSource.inventory,
            icon: Icons.kitchen_outlined,
            label: l10n.diaryQuickEatSourceInventory,
          ),
          _item(
            value: DiaryQuickEatSource.barcode,
            icon: Icons.qr_code_scanner_rounded,
            label: l10n.diaryQuickEatSourceBarcode,
          ),
          _item(
            value: DiaryQuickEatSource.manualSearch,
            icon: Icons.search_rounded,
            label: l10n.diaryQuickEatSourceManualSearch,
          ),
          _item(
            value: DiaryQuickEatSource.ai,
            icon: Icons.auto_awesome_rounded,
            label: l10n.diaryQuickEatSourceAi,
          ),
        ];
      },
    );
  }

  PopupMenuItem<DiaryQuickEatSource> _item({
    required DiaryQuickEatSource value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<DiaryQuickEatSource>(
      key: Key('diary_quick_add_source_${value.name}'),
      value: value,
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: AppSpacing.md),
          Text(label),
        ],
      ),
    );
  }
}
