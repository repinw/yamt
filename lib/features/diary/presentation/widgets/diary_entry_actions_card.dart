import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_action_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Entry" card of the diary entry details page: log the food again and
/// remove the entry.
class DiaryEntryActionsCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.isEnabled,
    required this.onRemove,
    this.onEatAgain,
    super.key,
  });

  /// Key of the line that logs the food again.
  static const eatAgainKey = Key('diary_entry_details_eat_again');

  /// Key of the line that removes the entry.
  static const removeKey = Key('diary_entry_details_remove');

  /// Whether the lines react to taps. They are muted while a change saves.
  final bool isEnabled;

  /// Removes the entry.
  final VoidCallback onRemove;

  /// Logs the food again. The line is hidden when null.
  final VoidCallback? onEatAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final onEatAgain = this.onEatAgain;

    return EatActionCard(
      title: l10n.diaryEntryDetailsCardTitle,
      actions: [
        if (onEatAgain != null)
          (
            key: eatAgainKey,
            icon: Icons.replay_rounded,
            label: l10n.caloriesEatAgainAction,
            color: colors.ink,
            onPressed: isEnabled ? onEatAgain : null,
          ),
        (
          key: removeKey,
          icon: Icons.delete_outline_rounded,
          label: l10n.caloriesRemoveEntryAction,
          color: Theme.of(context).colorScheme.error,
          onPressed: isEnabled ? onRemove : null,
        ),
      ],
    );
  }
}
