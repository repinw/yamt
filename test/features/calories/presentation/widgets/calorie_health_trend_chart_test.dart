import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_trend_chart.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/l10n/app_localizations.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders line chart with three legend labels', (tester) async {
    final snapshot = CalorieHealthTrendSnapshot(
      points: [
        CalorieHealthTrendPoint(
          day: DateTime(2026, 3, 14),
          intakeKcal: 1800,
          burnedKcal: 420,
          weightKg: 71.3,
          weightSource: CalorieHealthTrendWeightSource.health,
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
      _buildTestApp(CalorieHealthTrendChart(snapshot: snapshot)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Burned'), findsOneWidget);
    expect(find.text('Intake'), findsOneWidget);
  });

  testWidgets('renders empty state when no trend values exist', (tester) async {
    final snapshot = CalorieHealthTrendSnapshot(
      points: [
        CalorieHealthTrendPoint(
          day: DateTime(2026, 3, 14),
          intakeKcal: 0,
          burnedKcal: null,
          weightKg: null,
          weightSource: CalorieHealthTrendWeightSource.none,
        ),
      ],
      healthAccessState: HealthDataAccessState.permissionRequired,
      healthPlatform: HealthPlatform.android,
    );

    await tester.pumpWidget(
      _buildTestApp(CalorieHealthTrendChart(snapshot: snapshot)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No trend data yet for this 7-day window.'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
  });
}
