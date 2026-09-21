import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';

/// Goal cycle dropdown selector for TDEE analytics.
class TdeeGoalSelector extends StatelessWidget {
  /// Creates the goal cycle selector.
  const new({
    required this.selectedCycleIds,
    required this.availableCycles,
    required this.onToggleCycle,
    super.key,
  });

  /// IDs of the selected cycles; `all` means every cycle.
  final Set<String> selectedCycleIds;

  /// All available cycles to pick from.
  final List<TdeeAnalyticsGoalCycle> availableCycles;

  /// Called with the id of a cycle that the user taps.
  final ValueChanged<String> onToggleCycle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCycles = availableCycles
        .where((cycle) => selectedCycleIds.contains(cycle.id))
        .toList(growable: false);
    final selectedCycle = selectedCycles.length == 1
        ? selectedCycles.single
        : availableCycles.firstWhere(
            (cycle) => cycle.isAllGoals,
            orElse: () => availableCycles.first,
          );

    return PopupMenuButton<String>(
      onSelected: onToggleCycle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      itemBuilder: (context) => [
        for (final cycle in availableCycles)
          PopupMenuItem<String>(
            value: cycle.id,
            child: Row(
              children: [
                Icon(
                  cycle.isAllGoals
                      ? Icons.public_rounded
                      : Icons.track_changes_rounded,
                  size: 20,
                  color: selectedCycleIds.contains(cycle.id)
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    cycle.title,
                    style: TextStyle(
                      fontWeight: selectedCycleIds.contains(cycle.id)
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selectedCycleIds.contains(cycle.id))
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedCycle.isAllGoals
                  ? Icons.public_rounded
                  : Icons.track_changes_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                selectedCycle.title,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
