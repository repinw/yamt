import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/presentation/'
    'calorie_health_trends_page_keys.dart';
import 'package:yamt/features/calories/presentation/'
    'calorie_health_trends_page.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_health_trend_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildTestApp({required List<dynamic> overrides}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const CalorieHealthTrendsPage(),
    ),
  );
}

void main() {
  testWidgets('shows trends page title and chart content', (tester) async {
    final snapshot = CalorieHealthTrendSnapshot(
      points: [
        CalorieHealthTrendPoint(
          day: DateTime(2026, 3, 14),
          intakeKcal: 1800,
          burnedKcal: 420,
          weightKg: 71.3,
          weightSource: CalorieHealthTrendWeightSource.manual,
        ),
        CalorieHealthTrendPoint(
          day: DateTime(2026, 3, 15),
          intakeKcal: 2100,
          burnedKcal: 510,
          weightKg: 71.0,
          weightSource: CalorieHealthTrendWeightSource.health,
        ),
      ],
      healthAccessState: HealthDataAccessState.ready,
      healthPlatform: HealthPlatform.android,
    );

    await tester.pumpWidget(
      _buildTestApp(
        overrides: [
          calorieHealthTrendSnapshotProvider.overrideWith((ref) async {
            return snapshot;
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Health trends'), findsOneWidget);
    expect(find.text('7-day health chart'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Burned'), findsOneWidget);
    expect(find.text('Intake'), findsOneWidget);
    expect(find.text('Daily weights'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Health Connect'), findsOneWidget);
    expect(
      find.byKey(CalorieHealthTrendsPageKeys.weightRow('2026-3-15')),
      findsOneWidget,
    );
  });
}
