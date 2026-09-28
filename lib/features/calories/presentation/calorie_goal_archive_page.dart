import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/calories/application/calorie_goal_archive_provider.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';
import 'package:yamt/features/calories/presentation/widgets/goal_archive/goal_archive_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Lists the current and archived weight goals.
class CalorieGoalArchivePage extends ConsumerStatefulWidget {
  /// Creates the goal archive page.
  const new({super.key});

  @override
  ConsumerState<CalorieGoalArchivePage> createState() =>
      _CalorieGoalArchivePageState();
}

class _CalorieGoalArchivePageState
    extends ConsumerState<CalorieGoalArchivePage> {
  final Set<String> _selectedIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final archive = ref.watch(calorieGoalArchiveProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.goalArchiveTitle)),
      body: archive.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorRetryView(
          onRetry: () => ref.invalidate(calorieGoalArchiveProvider),
          message: l10n.goalArchiveLoadFailed,
          retryLabel: l10n.goalArchiveRetryAction,
        ),
        data: (cycles) => _buildArchiveList(cycles, l10n),
      ),
    );
  }

  Widget _buildArchiveList(
    List<TdeeAnalyticsGoalCycle> cycles,
    AppLocalizations l10n,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(l10n.goalArchiveSelectHint),
        const SizedBox(height: AppSpacing.md),
        for (final cycle in cycles) ...[
          GoalArchiveCard(
            key: ValueKey<String>(cycle.id),
            cycle: cycle,
            selected: _selectedIds.contains(cycle.id),
            onOpen: () => _openAnalytics(<String>{cycle.id}),
            onSelected: (selected) => _toggleSelection(cycle.id, selected),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_selectedIds.isNotEmpty)
          FilledButton.icon(
            onPressed: () => _openAnalytics(_selectedIds),
            icon: const Icon(Icons.insights_rounded),
            label: Text(l10n.goalArchiveOpenAnalytics),
          ),
      ],
    );
  }

  void _toggleSelection(String id, bool selected) {
    setState(() => selected ? _selectedIds.add(id) : _selectedIds.remove(id));
  }

  void _openAnalytics(Set<String> ids) {
    unawaited(context.push(AppRoutes.homeCaloriesAnalyticsPath(cycleIds: ids)));
  }
}
