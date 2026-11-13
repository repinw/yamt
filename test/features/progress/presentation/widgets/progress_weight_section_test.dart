import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/presentation/widgets/progress_weight_section.dart';
import 'package:yamt/l10n/app_localizations.dart';
import 'package:yamt/l10n/app_localizations_de.dart';

import '../../../../helpers/progress_source_overrides.dart';
import '../../../calories/support/fake_calories_repositories.dart';

void main() {
  testWidgets('the head fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(960, 3000);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final settings = FakeCalorieSettingsRepository(
      initialSettings: progressSettings(),
    );
    addTearDown(settings.dispose);
    final calorieLog = FakeCalorieLogRepository();
    addTearDown(calorieLog.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: progressSourceOverrides(
          settingsRepository: settings,
          calorieLog: calorieLog,
        ),
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: ProgressWeightSection(scope: ProgressScope.goal),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizationsDe();
    expect(find.text(l10n.progressWeightRateSince('7. Sept.')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
