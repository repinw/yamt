import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/progress/application/progress_weight_list_provider.dart';
import 'package:yamt/features/progress/domain/progress_weight_list.dart';
import 'package:yamt/features/progress/presentation/progress_weight_entry_flow.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_section_state.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_health_connect.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_list_summary.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_run_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Every weighing of a range, newest first and grouped by 7-day runs, under
/// the change of the trend and the chart with the goal weight.
class ProgressWeightsPage extends ConsumerStatefulWidget {
  /// Creates the weight list page.
  const new({super.key});

  /// Stable key of the chip for [range].
  static ValueKey<String> rangeKey(ProgressWeightRange range) =>
      ValueKey<String>('progress-weights-range-${range.name}');

  /// Stable key of the add button.
  static const addKey = ValueKey<String>('progress-weights-add');

  @override
  ConsumerState<ProgressWeightsPage> createState() =>
      _ProgressWeightsPageState();
}

class _ProgressWeightsPageState extends ConsumerState<ProgressWeightsPage> {
  ProgressWeightRange _range = ProgressWeightRange.goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = ref.watch(progressWeightListProvider(_range));
    final rows = <Widget Function()>[
      () => Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final range in ProgressWeightRange.values)
            ChoiceChip(
              key: ProgressWeightsPage.rangeKey(range),
              label: Text(switch (range) {
                ProgressWeightRange.goal => l10n.progressWeightsRangeGoal,
                ProgressWeightRange.fourWeeks =>
                  l10n.progressWeightsRangeFourWeeks,
                ProgressWeightRange.all => l10n.progressWeightsRangeAll,
              }),
              selected: range == _range,
              onSelected: (_) => setState(() => _range = range),
            ),
        ],
      ),
      () => const SizedBox(height: AppSpacing.md),
      ...list.when(
        data: (list) => [
          () => ProgressWeightListSummary(list: list),
          () => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: ProgressWeightHealthCard(),
          ),
          if (list.runs.isEmpty)
            () => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: ProgressSectionNote(text: l10n.progressWeightsEmpty),
            ),
          for (final run in list.runs) ...[
            () => ProgressWeightRunHeader(
              run: run,
              currentYear: list.trend.days.last.day.year,
            ),
            for (final weighing in run.weighings)
              () => ProgressWeighingRow(
                weighing: weighing,
                currentYear: list.trend.days.last.day.year,
              ),
          ],
        ],
        loading: () => [() => const ProgressSectionLoading()],
        error: (_, _) => [() => const ProgressSectionError()],
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progressWeightsTitle),
        actions: [
          const ProgressWeightHealthButton(),
          IconButton(
            key: ProgressWeightsPage.addKey,
            tooltip: l10n.diaryWeightAddAction,
            onPressed: () => unawaited(showProgressWeightEntry(context)),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView.builder(
        padding: responsivePagePadding(
          context,
          top: AppSpacing.md,
          bottom: AppSpacing.xl,
        ),
        itemCount: rows.length,
        itemBuilder: (context, index) => rows[index](),
      ),
    );
  }
}
