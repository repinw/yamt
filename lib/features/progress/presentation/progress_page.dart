import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/core/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/controllers/progress_scope_controller.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_day_type_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_goal_card.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_scope_switch.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_tdee_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_week_section.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Home tab that shows how the current week and the longer trend are going:
/// the goal, the week with its budget, the weight trend, the TDEE per
/// check-in, and training days against rest days.
class ProgressPage extends ConsumerWidget {
  /// Creates the progress page.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final rule = FoodLabelColors.of(context).rule;
    final scope = ref.watch(progressScopeControllerProvider);
    final isGoal = scope == ProgressScope.goal;
    final sections = <Widget>[
      if (isGoal) const ProgressWeekSection(),
      ProgressWeightSection(scope: scope),
      ProgressTdeeSection(scope: scope),
      ProgressDayTypeSection(scope: scope),
    ];
    return CustomScrollView(
      slivers: [
        HomeShellTabTopChrome(title: l10n.homeProgress),
        SliverPadding(
          padding: responsivePagePadding(
            context,
            top: AppSpacing.md,
            bottom: homeShellPageBottomPadding(context),
          ),
          sliver: SliverList.list(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.narrowContentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ProgressScopeSwitch(),
                      const SizedBox(height: AppSpacing.md),
                      if (isGoal) const ProgressGoalCard(),
                      for (final (index, section) in sections.indexed) ...[
                        if (index > 0 || isGoal) ...[
                          const SizedBox(height: AppSpacing.xxxl),
                          Divider(height: AppSizes.hairline, color: rule),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                        section,
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
