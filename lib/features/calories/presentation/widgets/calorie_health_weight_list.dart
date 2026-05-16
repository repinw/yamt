import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/application/calorie_weight_state_refresh.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/calorie_health_trends_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_weight_dialog.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/presentation/controllers/'
    'manual_health_weight_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calorie health weight list.
class CalorieHealthWeightList extends ConsumerWidget {
  /// The calorie health weight list.
  const CalorieHealthWeightList({required this.snapshot, super.key});

  /// The snapshot.
  final CalorieHealthTrendSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.caloriesHealthTrendsWeightsTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.caloriesHealthTrendsWeightsSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.md),
        for (
          var index = snapshot.points.length - 1;
          index >= 0;
          index -= 1
        ) ...[
          _WeightDayRow(
            point: snapshot.points[index],
            dayLabel: dateFormat.format(snapshot.points[index].day),
            sourceLabel: _weightSourceLabel(
              l10n: l10n,
              platform: snapshot.healthPlatform,
              source: snapshot.points[index].weightSource,
            ),
            onTap: () => _editWeightForDay(
              context: context,
              point: snapshot.points[index],
              dayLabel: dateFormat.format(snapshot.points[index].day),
            ),
          ),
          if (index > 0) const Divider(height: AppSpacing.xl),
        ],
      ],
    );
  }

  Future<void> _editWeightForDay({
    required BuildContext context,
    required CalorieHealthTrendPoint point,
    required String dayLabel,
  }) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final controllerSubscription = container.listen(
      manualHealthWeightEntriesControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final refreshSubscription = container.listen(
      calorieWeightStateRefreshProvider,
      (_, _) {},
      fireImmediately: true,
    );
    final controller = container.read(
      manualHealthWeightEntriesControllerProvider.notifier,
    );
    try {
      await showCalorieHealthWeightDialog(
        context: context,
        dayLabel: dayLabel,
        initialWeightKg: point.weightKg,
        hasManualWeight:
            point.weightSource == CalorieHealthTrendWeightSource.manual,
        onSaveWeight: (weightKg) async {
          final saved = await controller.saveEntry(
            day: point.day,
            weightKg: weightKg,
          );
          if (saved) {
            await _refreshWeightDependents(container, day: point.day);
          }
          return saved;
        },
        onClearWeight: () async {
          final deleted = await controller.deleteEntryForDay(point.day);
          if (deleted) {
            await _refreshWeightDependents(container, day: point.day);
          }
          return deleted;
        },
      );
    } finally {
      refreshSubscription.close();
      controllerSubscription.close();
    }
  }

  Future<void> _refreshWeightDependents(
    ProviderContainer container, {
    required DateTime day,
  }) {
    return container.read(calorieWeightStateRefreshProvider)(day: day);
  }

  String _weightSourceLabel({
    required AppLocalizations l10n,
    required HealthPlatform platform,
    required CalorieHealthTrendWeightSource source,
  }) {
    return switch (source) {
      CalorieHealthTrendWeightSource.manual =>
        l10n.caloriesHealthTrendsWeightSourceManual,
      CalorieHealthTrendWeightSource.health => switch (platform) {
        HealthPlatform.ios => l10n.caloriesHealthTrendsWeightSourceAppleHealth,
        _ => l10n.caloriesHealthTrendsWeightSourceHealthConnect,
      },
      CalorieHealthTrendWeightSource.none =>
        l10n.caloriesHealthTrendsWeightMissing,
    };
  }
}

class _WeightDayRow extends StatelessWidget {
  const _WeightDayRow({
    required this.point,
    required this.dayLabel,
    required this.sourceLabel,
    required this.onTap,
  });

  final CalorieHealthTrendPoint point;
  final String dayLabel;
  final String sourceLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final dayKey = diaryDayKey(point.day);
    final actionLabel = point.weightKg == null
        ? l10n.caloriesHealthTrendsWeightAddAction
        : l10n.caloriesHealthTrendsWeightEditAction;
    final weightLabel = point.weightKg == null
        ? '—'
        : '${point.weightKg!.toStringAsFixed(1)} ${l10n.caloriesUnitKg}';

    return Row(
      key: CalorieHealthTrendsKeys.weightRow(dayKey),
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                sourceLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          weightLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(
          key: CalorieHealthTrendsKeys.weightActionButton(dayKey),
          onPressed: onTap,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
