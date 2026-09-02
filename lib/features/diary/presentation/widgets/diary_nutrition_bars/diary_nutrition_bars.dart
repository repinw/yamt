import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/widgets/metric_card_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars_content.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_nutrition_bars/diary_nutrition_bars_skeleton.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Stable keys for diary nutrition bar tests.
abstract final class DiaryNutritionBarsKeys {
  /// Retry button key.
  static const retryButton = ValueKey<String>(
    'diary-nutrition-bars-retry-button',
  );
}

/// Macro nutrition bars for the diary page.
class DiaryNutritionBars extends ConsumerStatefulWidget {
  /// Creates standalone diary nutrition bars.
  const DiaryNutritionBars({
    required this.selectedDay,
    super.key,
  }) : _framed = true,
       _showTitle = true;

  /// Creates embedded diary nutrition bars without a standalone card frame.
  const DiaryNutritionBars.embedded({
    required this.selectedDay,
    super.key,
  }) : _framed = false,
       _showTitle = false;

  /// The selected diary day.
  final DateTime selectedDay;

  /// Whether to draw the standalone card shell.
  final bool _framed;

  /// Whether to show the macro section title.
  final bool _showTitle;

  @override
  ConsumerState<DiaryNutritionBars> createState() => _DiaryNutritionBarsState();
}

class _DiaryNutritionBarsState extends ConsumerState<DiaryNutritionBars>
    with AutomaticKeepAliveClientMixin<DiaryNutritionBars> {
  DiaryNutritionBarsData? _lastData;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final normalizedDay = normalizeDiaryDay(widget.selectedDay);
    final dashboardState = ref.watch(
      diaryDayDashboardControllerProvider(normalizedDay),
    );
    final loadedData = dashboardState.data?.nutritionBars;
    if (loadedData != null) {
      _lastData = loadedData;
    }
    final data = loadedData ?? _lastData;
    final l10n = AppLocalizations.of(context)!;
    final showError = data == null && dashboardState.showError;

    final content = IconTheme.merge(
      data: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      child: showError
          ? MetricErrorRetryContent(
              message: l10n.diaryNutritionLoadFailed,
              retryLabel: l10n.caloriesRetryAction,
              retryButtonKey: DiaryNutritionBarsKeys.retryButton,
              onRetry: () => _retryNutritionBars(normalizedDay),
            )
          : data == null
          ? DiaryNutritionBarsSkeleton(showTitle: widget._showTitle)
          : DiaryNutritionBarsContent(
              data: data,
              showTitle: widget._showTitle,
            ),
    );

    if (!widget._framed) {
      return content;
    }

    return MetricDetailCardShell(child: content);
  }

  void _retryNutritionBars(DateTime normalizedDay) {
    unawaited(
      ref
          .read(diaryDayDashboardControllerProvider(normalizedDay).notifier)
          .retry(),
    );
  }
}
