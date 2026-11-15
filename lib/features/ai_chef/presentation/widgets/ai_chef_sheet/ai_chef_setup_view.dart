import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_switch_list_tile.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/ai_chef_sheet/'
    'ai_chef_must_use_chips.dart';
import 'package:yamt/features/ai_chef/presentation/widgets/ai_chef_sheet/'
    'ai_chef_pill_row.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Start of the row text: icon width plus the gap after it.
const double _rowTextIndent = AppSizes.setupRowIcon + AppSpacing.lg;

/// Sets up a recipe idea in three rows without a title: "Vorrat zuerst"
/// with the "Unbedingt rein" picks, the wishes, and the stored "Bloß nicht"
/// list; then "Rezept vorschlagen".
class AiChefSetupView extends StatelessWidget {
  /// Creates setup view.
  const new({
    required this.includeInventory,
    required this.onIncludeInventoryChanged,
    required this.mustUseItems,
    required this.onPickMustUse,
    required this.onRemoveMustUse,
    required this.wishes,
    required this.onAddWish,
    required this.onRemoveWish,
    required this.excludedIngredients,
    required this.onAddExclusion,
    required this.onRemoveExclusion,
    required this.onGenerate,
    this.mustUseError,
    this.exclusionsError,
    this.onRetryExclusions,
    super.key,
  });

  /// Key of the Vorrat switch.
  static const inventoryKey = ValueKey<String>('ai-chef-inventory');

  /// Key of "Rezept vorschlagen".
  static const generateKey = ValueKey<String>('ai-chef-generate');

  /// Key prefix of the wish pills.
  static const wishKeys = 'ai-chef-wish';

  /// Key prefix of the "Bloß nicht" pills.
  static const exclusionKeys = 'ai-chef-exclusion';

  /// Whether active inventory should be sent to the AI.
  final bool includeInventory;

  /// Called when inventory option changes.
  final ValueChanged<bool> onIncludeInventoryChanged;

  /// The Vorrat items picked for "Unbedingt rein".
  final List<InventoryItem> mustUseItems;

  /// Called to open the "Unbedingt rein" pick sheet.
  final VoidCallback onPickMustUse;

  /// Called with the id of a picked item to remove.
  final ValueChanged<String> onRemoveMustUse;

  /// Says that the Vorrat for the picks could not be loaded.
  final String? mustUseError;

  /// The wishes for this idea.
  final List<String> wishes;

  /// Called with a new wish.
  final ValueChanged<String> onAddWish;

  /// Called with the wish to remove.
  final ValueChanged<String> onRemoveWish;

  /// The stored "Bloß nicht" list, or null while it loads.
  final List<String>? excludedIngredients;

  /// Says that loading or saving the "Bloß nicht" list failed.
  final String? exclusionsError;

  /// Called to load the "Bloß nicht" list again; null when that does not
  /// help.
  final VoidCallback? onRetryExclusions;

  /// Called with an ingredient to add to the "Bloß nicht" list.
  final ValueChanged<String> onAddExclusion;

  /// Called with an ingredient to remove from the "Bloß nicht" list.
  final ValueChanged<String> onRemoveExclusion;

  /// Called when generation starts.
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final mustUseError = this.mustUseError;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSwitchListTile(
          key: inventoryKey,
          value: includeInventory,
          onChanged: onIncludeInventoryChanged,
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.kitchen_outlined,
            size: AppSizes.setupRowIcon,
            color: colors.muted,
          ),
          title: Text(l10n.aiChefUseInventoryTitle),
          subtitle: Text(l10n.aiChefUseInventorySubtitle),
        ),
        if (includeInventory)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: _rowTextIndent,
              bottom: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [
                AiChefMustUseChips(
                  items: mustUseItems,
                  onPick: onPickMustUse,
                  onRemove: onRemoveMustUse,
                ),
                if (mustUseError != null) _ErrorText(mustUseError),
              ],
            ),
          ),
        const Divider(height: 1),
        _IconRow(
          icon: Icons.edit_outlined,
          child: AiChefPillRow(
            keyPrefix: wishKeys,
            label: l10n.aiChefWishesLabel,
            addLabel: l10n.aiChefWishesAddAction,
            hint: l10n.aiChefWishesHint,
            entries: wishes,
            onAdd: onAddWish,
            onRemove: onRemoveWish,
          ),
        ),
        const Divider(height: 1),
        _IconRow(
          icon: Icons.block_rounded,
          child: AiChefPillRow(
            keyPrefix: exclusionKeys,
            label: l10n.aiChefExclusionsLabel,
            addLabel: l10n.aiChefExclusionsAddAction,
            hint: l10n.aiChefExclusionsInputHint,
            entries: excludedIngredients,
            errorText: exclusionsError,
            onRetry: onRetryExclusions,
            onAdd: onAddExclusion,
            onRemove: onRemoveExclusion,
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          key: generateKey,
          onPressed: excludedIngredients == null ? null : onGenerate,
          style: FilledButton.styleFrom(
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            minimumSize: const Size.fromHeight(AppGraphit.buttonHeight),
          ),
          child: Text(
            l10n.aiChefGenerateAction,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _IconRow extends StatelessWidget {
  const new({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: AppSizes.setupRowIcon,
            color: FoodLabelColors.of(context).muted,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }
}
