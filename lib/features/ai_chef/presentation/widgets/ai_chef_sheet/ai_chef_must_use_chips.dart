import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The Vorrat items picked for "Unbedingt rein", as filled chips, plus the
/// chip that opens the pick sheet.
class AiChefMustUseChips extends StatelessWidget {
  /// Creates the chips.
  const new({
    required this.items,
    required this.onPick,
    required this.onRemove,
    super.key,
  });

  /// Key of the chip that opens the pick sheet.
  static const pickKey = ValueKey<String>('ai-chef-must-use-pick');

  /// Key of the chip for the item with [id].
  static ValueKey<String> chipKey(String id) =>
      ValueKey<String>('ai-chef-must-use-chip-$id');

  /// The picked items.
  final List<InventoryItem> items;

  /// Called to open the pick sheet.
  final VoidCallback onPick;

  /// Called with the id of the item to remove.
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items)
          InputChip(
            key: chipKey(item.id),
            label: Text(item.name),
            backgroundColor: colors.inverseSurface,
            labelStyle: theme.textTheme.labelLarge?.copyWith(
              color: colors.onInverseSurface,
            ),
            deleteIconColor: colors.onInverseSurface,
            side: BorderSide.none,
            onDeleted: () => onRemove(item.id),
            deleteButtonTooltipMessage: l10n.aiChefExclusionsRemoveTooltip(
              item.name,
            ),
          ),
        ActionChip(
          key: pickKey,
          avatar: const Icon(Icons.add_rounded),
          label: Text(l10n.aiChefMustUseLabel),
          onPressed: onPick,
        ),
      ],
    );
  }
}
