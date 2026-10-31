import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/features/activity/presentation/diary_weight_tracking_flow.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/application/diary_day_weight_trend_provider.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_load_error.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_no_value.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number_body.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_sparkline.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_sheet/diary_weekly_checkin_number_format.dart';
import 'package:yamt/features/health/domain/recent_weight_trend.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The trend weight as a number or as a line of the recent days.
const diaryWeightTile = DiaryDashboardTile(
  spec: diaryWeightTileSpec,
  icon: Icons.monitor_weight_outlined,
  label: _label,
  modes: [
    DiaryTileMode(
      id: DiaryTileModes.number,
      icon: Icons.pin_outlined,
      label: _number,
    ),
    DiaryTileMode(
      id: DiaryTileModes.sparkline,
      icon: Icons.show_chart_rounded,
      label: _sparkline,
    ),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileWeight;

String _number(AppLocalizations l10n) => l10n.diaryDashboardWeightModeNumber;

String _sparkline(AppLocalizations l10n) =>
    l10n.diaryDashboardWeightModeSparkline;

Widget _build(DiaryTileArgs args) => DiaryWeightTileContent(args: args);

/// The inside of the weight tile; a tap adds a weighing of the day.
class DiaryWeightTileContent extends ConsumerWidget {
  /// Creates the content for [args].
  const new({required this.args, super.key});

  /// Day, size and mode of the tile.
  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final today = ref.watch(diaryTodayProvider);
    const dash = DiaryTileNoValue();
    final content = ref
        .watch(diaryDayWeightTrendProvider(args.day))
        .when(
          data: (trend) =>
              switch (trend.trendWeightKg ?? trend.latestWeighInKg) {
                final weightKg? => _WeightView(
                  args: args,
                  trend: trend,
                  weightKg: weightKg,
                ),
                null => dash,
              },
          loading: () => dash,
          error: (_, _) => DiaryTileLoadError(size: args.size),
        );
    if (args.day.isAfter(today)) return content;

    return Semantics(
      button: true,
      label: l10n.diaryWeightAddAction,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(
          ref
              .read(diaryWeightTrackingFlowProvider)
              .showDialogForDay(
                context: context,
                selectedDay: args.day,
                day: args.day,
              ),
        ),
        child: content,
      ),
    );
  }
}

class _WeightView extends StatelessWidget {
  const new({required this.args, required this.trend, required this.weightKg});

  final DiaryTileArgs args;
  final RecentWeightTrend trend;
  final double weightKg;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final format = DiaryWeeklyCheckInNumberFormat(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final isSparkline = args.mode == DiaryTileModes.sparkline;
    final number = DiaryTileNumber(
      format.kg(weightKg),
      unit: args.size == DiaryTileSize.s1x1 ? null : l10n.caloriesUnitKg,
    );
    final line = DiaryTileSparkline(
      values: [for (final day in trend.days) day.trendWeightKg],
      minRange: AppSizes.profileWeightChartMinRangeKg,
    );
    final body = DiaryTileNumberBody(
      number: number,
      captions: [
        if (trend.trendKgPerWeek case final perWeek?)
          DiaryTileCaption(
            l10n.diaryDashboardWeightPerWeek(format.signedKg(perWeek)),
            icon: _trendIcon(perWeek),
          ),
      ],
    );

    return switch (args.size) {
      DiaryTileSize.s1x1 => isSparkline ? line : number,
      DiaryTileSize.s2x2 => Column(
        spacing: AppDashboard.tileInnerGap,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: body),
          Expanded(child: line),
        ],
      ),
      DiaryTileSize.s2x1 when !isSparkline => body,
      _ => Row(
        spacing: AppDashboard.tileInnerGap,
        children: [
          if (isSparkline) Expanded(child: line),
          // Half of 2×1 is too narrow for the caption.
          Expanded(child: args.size == DiaryTileSize.s2x1 ? number : body),
          if (!isSparkline) Expanded(child: line),
        ],
      ),
    };
  }

  static IconData _trendIcon(double perWeek) {
    if (perWeek <= -AppDashboard.weightFlatKgPerWeek) {
      return Icons.trending_down_rounded;
    }
    if (perWeek >= AppDashboard.weightFlatKgPerWeek) {
      return Icons.trending_up_rounded;
    }
    return Icons.trending_flat_rounded;
  }
}
