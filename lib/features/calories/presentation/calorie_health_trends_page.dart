import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_trend_chart.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_weight_list.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'diary_health_card_parts.dart';
import 'package:yamt/features/calories/provider/calorie_health_trend_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CalorieHealthTrendsPage extends ConsumerWidget {
  const CalorieHealthTrendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trendAsync = ref.watch(calorieHealthTrendSnapshotProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.caloriesHealthTrendsPageTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        children: [
          DecoratedBox(
            decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
              colors,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Padding(
              padding: AppInsets.card,
              child: trendAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(l10n.caloriesLoadFailed),
                data: (snapshot) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.caloriesHealthTrendsChartTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.caloriesHealthTrendsChartSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (snapshot.healthAccessState !=
                          HealthDataAccessState.ready) ...[
                        const SizedBox(height: AppSpacing.lg),
                        DiaryHealthConnectionPrompt(
                          accessState: snapshot.healthAccessState,
                          androidPermissionBody:
                              l10n.settingsHealthConnectSubtitle,
                          iosPermissionBody:
                              l10n.settingsAppleHealthConnectSubtitle,
                          historyBody: l10n.settingsHealthHistorySubtitle,
                          installBody: l10n.settingsHealthInstallSubtitle,
                          unsupportedBody: l10n.caloriesHealthTrendsHealthHint,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      CalorieHealthTrendChart(snapshot: snapshot),
                      const SizedBox(height: AppSpacing.xl),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),
                      CalorieHealthWeightList(snapshot: snapshot),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
