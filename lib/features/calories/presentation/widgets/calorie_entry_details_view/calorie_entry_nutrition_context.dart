import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Muted line below the nutrition table with the entry's share of the day's
/// calorie goal.
class CalorieEntryNutritionContext extends ConsumerWidget {
  /// Creates the goal share line.
  const new({required this.entry, super.key});

  /// Entry whose context is shown.
  final CalorieEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final goalKcal = ref
        .watch(
          resolvedCalorieGoalForDayProvider(normalizeDiaryDay(entry.loggedAt)),
        )
        .asData
        ?.value
        .goalKcal;
    if (goalKcal == null || goalKcal <= 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      key: CalorieEntryDetailKeys.nutritionContext,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.xs,
        0,
      ),
      child: Text(
        l10n.caloriesEntryGoalShare((entry.totalKcal / goalKcal * 100).round()),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
