import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_week_balance_summary_banner.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('renders week balance summary banner content', (tester) async {
    final overview = CalorieWeekOverview(
      days: <CalorieWeekDayOverview>[
        CalorieWeekDayOverview(
          date: DateTime(2026, 3, 20),
          totalKcal: 1800,
          goalKcal: 2200,
          entryCount: 1,
        ),
      ],
      totalConsumedKcal: 1800,
      totalGoalKcal: 2200,
      remainingKcal: 400,
      balanceStartDate: DateTime(2026, 3, 20),
      carryoverBeforeTodayKcal: 400,
      todayFlexibleGoalKcal: 2600,
      goalStartsInFuture: false,
      nextGoalStartDate: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CalorieWeekBalanceSummaryBanner(
            overview: overview,
            referenceNow: DateTime(2026, 3, 21),
          ),
        ),
      ),
    );

    final l10n = AppLocalizations.of(
      tester.element(find.byType(CalorieWeekBalanceSummaryBanner)),
    )!;

    expect(find.byKey(CaloriesPageKeys.weekBalanceSummary), findsOneWidget);
    expect(find.byKey(CaloriesPageKeys.weekBalanceSummaryIcon), findsOneWidget);
    expect(find.text(l10n.caloriesWeekBalanceSaved(400)), findsOneWidget);
  });
}
