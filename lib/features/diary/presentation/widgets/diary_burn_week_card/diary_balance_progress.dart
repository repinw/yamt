import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_compact_balance_progress_bar.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_expanded_balance_progress_bar.dart';

/// Burn Week pacing progress bar.
class DiaryBalanceProgressBar extends StatelessWidget {
  /// Creates a diary balance progress bar.
  const new({
    required this.consumedKcal,
    required this.targetKcal,
    required this.weeklyGoalKcal,
    required this.totalDays,
    this.compact = false,
    super.key,
  });

  /// Consumed calories in the displayed Burn Week.
  final double consumedKcal;

  /// Pacing target in calories for the displayed day.
  final double targetKcal;

  /// Stable weekly goal used as the bar maximum.
  final double weeklyGoalKcal;

  /// Total days represented by the bar.
  final int totalDays;

  /// Whether to render the slim diary summary version.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return DiaryCompactBalanceProgressBar(
        consumedKcal: consumedKcal,
        targetKcal: targetKcal,
        weeklyGoalKcal: weeklyGoalKcal,
        totalDays: totalDays,
      );
    }

    return DiaryExpandedBalanceProgressBar(
      consumedKcal: consumedKcal,
      targetKcal: targetKcal,
      weeklyGoalKcal: weeklyGoalKcal,
      totalDays: totalDays,
    );
  }
}
