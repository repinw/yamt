import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Footer actions of the calorie entry details sheet.
///
/// Changes save on their own, so the footer holds only the remove action and
/// the shortcut to log the same food again.
class CalorieEntryDetailsSheetFooter extends StatelessWidget {
  /// Creates a details sheet footer.
  const new({
    required this.canEatAgain,
    required this.isSaving,
    required this.onReturnToInventory,
    required this.onEatAgain,
    super.key,
  });

  /// Whether the entry can be logged again.
  final bool canEatAgain;

  /// Whether a mutation is in progress.
  final bool isSaving;

  /// Called when removing the entry.
  final VoidCallback onReturnToInventory;

  /// Called when logging the same food again.
  final VoidCallback onEatAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          0,
          AppSpacing.xl,
          AppSpacing.xs,
        ),
        child: Row(
          children: [
            IconButton(
              key: CalorieEntryDetailKeys.returnToInventoryButton,
              onPressed: isSaving ? null : onReturnToInventory,
              tooltip: l10n.caloriesRemoveEntryAction,
              color: colors.onSurfaceVariant,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            if (canEatAgain) const SizedBox(width: AppSpacing.xs),
            if (canEatAgain)
              Expanded(
                child: FilledButton.tonalIcon(
                  key: CalorieEntryDetailKeys.eatAgainButton,
                  onPressed: isSaving ? null : onEatAgain,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSizes.minTapTarget),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.caloriesEatAgainAction),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
