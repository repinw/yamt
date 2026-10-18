import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/progress/presentation/progress_weights_page.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_weight_list_summary.dart';
import 'package:yamt/features/settings/presentation/profile_page.dart';
import 'package:yamt/features/settings/presentation/widgets/profile/'
    'profile_weight_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/progress_source_overrides.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the profile weight card opens all weights', (tester) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: progressSettings(),
    );
    addTearDown(settings.dispose);
    final calorieLog = FakeCalorieLogRepository();
    addTearDown(calorieLog.dispose);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const ProfilePage()),
        GoRoute(
          path: AppRoutes.homeProgressWeights,
          builder: (context, state) => const ProgressWeightsPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: progressSourceOverrides(
          settingsRepository: settings,
          calorieLog: calorieLog,
        ),
        child: MaterialApp.router(
          locale: const Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final allWeights = find.byKey(ProfileWeightCard.allWeightsKey);
    await tester.ensureVisible(allWeights);
    await tester.pumpAndSettle();
    await tester.tap(allWeights);
    await tester.pumpAndSettle();

    expect(find.byKey(ProgressWeightListSummary.summaryKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
