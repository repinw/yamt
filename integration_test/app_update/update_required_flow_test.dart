import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/data/app_version_config_repository.dart';
import 'package:yamt/core/domain/app_update_status.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/app_update/presentation/update_required_page.dart';
import 'package:yamt/features/app_update/presentation/widgets/app_update_keys.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/memory_app_preferences.dart';

class _RouterHarness extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: ref.watch(appRouterProvider),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

const _stepDuration = Duration(milliseconds: 400);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('an app below the minimum version shows only the update page', (
    tester,
  ) async {
    final status = StreamController<AppUpdateStatus>.broadcast();
    addTearDown(status.close);
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(null),
        ),
        appUpdateStatusProvider.overrideWith((ref) => status.stream),
      ],
    );
    addTearDown(container.dispose);
    String currentRoute() => container.read(appRouterProvider).state.uri.path;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _RouterHarness(),
      ),
    );
    status.add(const AppUpdateRequired());
    await _pumpStep(tester);

    expect(currentRoute(), AppRoutes.updateRequired);
    expect(find.byType(UpdateRequiredPage), findsOneWidget);
    expect(find.byKey(AppUpdateKeys.requiredUpdateAction), findsOneWidget);

    status.add(const AppUpToDate());
    await _pumpStep(tester);

    expect(currentRoute(), AppRoutes.calorieGoalSetup);
  });
}

Future<void> _pumpStep(WidgetTester tester) async {
  await tester.pump();
  await Future<void>.delayed(_stepDuration);
  await tester.pump();
}
