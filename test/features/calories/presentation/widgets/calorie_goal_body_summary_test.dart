import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_goal_body_summary.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('lists the body data and opens the profile to change it', (
    tester,
  ) async {
    final profile = const CalorieCalculatorProfile.defaults().copyWith(
      sex: CalorieCalculatorSex.female,
      heightCm: 168,
      birthDate: DateTime(1994, 3, 14),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => CalorieGoalBodySummary(
                  profile: profile,
                  today: DateTime(2026, 9, 27),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.homeProfile,
          builder: (_, _) => const Scaffold(body: Text('Profile page')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Weiblich'), findsOneWidget);
    expect(find.text('168 cm'), findsOneWidget);
    expect(find.text('32 Jahre · 14.3.1994'), findsOneWidget);

    await tester.tap(find.byKey(CalorieGoalBodySummary.editInProfileKey));
    await tester.pumpAndSettle();

    expect(find.byType(CalorieGoalBodySummary), findsNothing);
    expect(find.text('Profile page'), findsOneWidget);
  });
}
