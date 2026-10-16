import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/core/widgets/home_shell_menu_button.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog_keys.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/health/data/progress_photo_repository.dart';
import 'package:yamt/features/health/domain/progress_photo.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';
import 'package:yamt/features/home/presentation/widgets/home_menu_panel.dart';
import 'package:yamt/features/home/presentation/widgets/inventory_add_actions.dart';
import 'package:yamt/features/home/presentation/widgets/progress_actions.dart';
import 'package:yamt/features/progress/presentation/progress_page.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_day_chart.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_weight_section.dart';
import 'package:yamt/features/scanner/data/receipt_ai_repository.dart';
import 'package:yamt/features/scanner/data/receipt_gateway_providers.dart';
import 'package:yamt/features/scanner/presentation/flow/receipt_camera_supported.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/scanner/fakes/fake_receipt_ai_repository.dart';
import '../../test/features/scanner/fakes/fake_receipt_product_resolver.dart';
import '../../test/helpers/fake_progress_photo_repository.dart';
import '../../test/helpers/progress_source_overrides.dart';

const _hubPageKey = ValueKey<String>('home-actions-test-hub');
const _settingsPageKey = ValueKey<String>('home-actions-test-settings');

GoRoute _placeholder(String path, {Key? key}) {
  return GoRoute(
    path: path,
    builder: (context, state) => Scaffold(body: SizedBox.expand(key: key)),
  );
}

/// The shell with placeholder tabs, except the real Fortschritt page.
///
/// [sources] back Fortschritt with data and a user profile; without them the
/// user has no profile.
Widget _buildHarness({
  String initialLocation = AppRoutes.homeInventory,
  List<Override>? sources,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeInventory)]),
          StatefulShellBranch(
            routes: [
              // The Diary top bar opens the side menu through this button.
              GoRoute(
                path: AppRoutes.homeDiary,
                builder: (context, state) =>
                    const Scaffold(body: Center(child: HomeShellMenuButton())),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [_placeholder(AppRoutes.homeInventoryTemplates)],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.homeProgress,
                builder: (context, state) => const ProgressPage(),
              ),
            ],
          ),
        ],
      ),
      _placeholder(AppRoutes.homeProductSearchHub, key: _hubPageKey),
      _placeholder(AppRoutes.homeSettings, key: _settingsPageKey),
    ],
  );
  addTearDown(router.dispose);

  // The Vorrat actions ask the scan coordinator whether a camera exists, so
  // its AI and product lookups are fakes.
  final container = ProviderContainer(
    overrides: [
      receiptCameraSupportedProvider.overrideWithValue(true),
      receiptAiRepositoryProvider.overrideWithValue(FakeReceiptAiRepository()),
      receiptProductResolverProvider.overrideWithValue(
        FakeReceiptProductResolver(),
      ),
      ...?sources,
      if (sources == null)
        userProfileProvider.overrideWithValue(const AsyncData(null)),
    ],
  );
  addTearDown(container.dispose);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      locale: const Locale('en'),
      routerConfig: router,
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// The weigh-in of today in the weight chart of Fortschritt.
double? _todaysWeighIn(WidgetTester tester) {
  final chart = tester.widget<ProgressDayChart>(
    find.descendant(
      of: find.byKey(ProgressWeightSection.sectionKey),
      matching: find.byType(ProgressDayChart),
    ),
  );
  return chart.days.last.dot;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the action button opens the Vorrat actions and runs one', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();

    expect(find.byType(HomeActionPanel), findsOneWidget);
    expect(find.byKey(InventoryAddActionKeys.barcode), findsOneWidget);
    expect(find.byKey(InventoryAddActionKeys.receiptPhoto), findsOneWidget);

    await tester.tap(find.byKey(InventoryAddActionKeys.manualSearch));
    await tester.pumpAndSettle();

    expect(find.byKey(_hubPageKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the action button on Fortschritt enters the weight', (
    tester,
  ) async {
    final settings = FakeCalorieSettingsRepository(
      initialSettings: progressSettings(),
    );
    addTearDown(settings.dispose);
    final calorieLog = FakeCalorieLogRepository(
      initialEntries: progressEntries(),
    );
    addTearDown(calorieLog.dispose);
    await tester.pumpWidget(
      _buildHarness(
        initialLocation: AppRoutes.homeProgress,
        sources: progressSourceOverrides(
          settingsRepository: settings,
          calorieLog: calorieLog,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(ProgressWeightSection.sectionKey),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ProgressPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(_todaysWeighIn(tester), 82.0);

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProgressActionKeys.weigh));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
      '80.4',
    );
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogSaveButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsNothing);
    expect(_todaysWeighIn(tester), 80.4);

    // The weight of today can be deleted from the same dialog.
    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProgressActionKeys.weigh));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeightDialogKeys.weightDialogClearButton));
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsNothing);
    expect(_todaysWeighIn(tester), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the action panel on Fortschritt adds a progress photo', (
    tester,
  ) async {
    final photos = FakeProgressPhotoRepository(
      pickedImage: Uint8List.fromList(<int>[1, 2, 3]),
    );
    addTearDown(photos.dispose);
    await tester.pumpWidget(
      _buildHarness(
        initialLocation: AppRoutes.homeProgress,
        sources: [
          userProfileProvider.overrideWithValue(const AsyncData(null)),
          progressPhotoRepositoryProvider.overrideWithValue(photos),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProgressActionKeys.photo));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ProgressPhotoCaptureSheet.poseKey(ProgressPhotoPose.side)),
    );
    await tester.tap(find.byKey(ProgressPhotoCaptureSheet.cameraKey));
    await tester.pumpAndSettle();

    expect(photos.photos.single.pose, ProgressPhotoPose.side);
    expect(find.byType(ProgressPhotoCaptureSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the close button hides the action panel', (tester) async {
    await tester.pumpWidget(_buildHarness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeActionPanel.closeButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(HomeActionPanel), findsNothing);
    expect(find.byKey(HomeBottomNavBar.actionKey), findsOneWidget);
  });

  testWidgets('the side menu opens settings at the appearance section', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(initialLocation: AppRoutes.homeDiary),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(HomeShellMenuButton.buttonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeMenuPanel.appearanceTileKey));
    await tester.pumpAndSettle();

    final settings = find.byKey(_settingsPageKey);
    expect(settings, findsOneWidget);
    expect(
      GoRouterState.of(tester.element(settings)).uri,
      Uri.parse(AppRoutes.homeSettingsAppearance),
    );
    expect(tester.takeException(), isNull);
  });
}
