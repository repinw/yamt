import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/widgets/home_bottom_nav_bar.dart';
import 'package:yamt/features/activity/presentation/widgets/weight_card/'
    'diary_weight_dialog_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/progress_photo_capture_sheet.dart';
import 'package:yamt/features/home/home_page.dart';
import 'package:yamt/features/home/presentation/widgets/home_action_panel.dart';
import 'package:yamt/features/home/presentation/widgets/progress_actions.dart';
import 'package:yamt/features/progress/presentation/progress_page.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_day_chart.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_goal_card.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_section_header.dart';
import 'package:yamt/features/progress/presentation/widgets/'
    'progress_weight_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../helpers/fake_progress_photo_repository.dart';
import '../../helpers/progress_source_overrides.dart';
import '../calories/support/fake_calories_repositories.dart';

GoRoute _placeholder(String path) {
  return GoRoute(path: path, builder: (context, state) => const SizedBox());
}

/// Pumps the home shell on the Fortschritt tab with its real page, backed by
/// the Fortschritt examples: the last weigh-in is 82,0 kg today. The
/// weigh-ins load once [weighInsReady] completes, when it is given.
Future<void> _pumpProgressTab(
  WidgetTester tester, {
  Future<void>? weighInsReady,
  FakeProgressPhotoRepository? photos,
}) async {
  tester.view.physicalSize = const Size(1080, 6000);
  addTearDown(tester.view.reset);
  final settings = FakeCalorieSettingsRepository(
    initialSettings: progressSettings(),
  );
  addTearDown(settings.dispose);
  final calorieLog = FakeCalorieLogRepository(
    initialEntries: progressEntries(),
  );
  addTearDown(calorieLog.dispose);
  final router = GoRouter(
    initialLocation: AppRoutes.homeProgress,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomePage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeInventory)]),
          StatefulShellBranch(routes: [_placeholder(AppRoutes.homeDiary)]),
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
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: progressSourceOverrides(
        settingsRepository: settings,
        calorieLog: calorieLog,
        weighInsReady: weighInsReady,
        photos: photos,
      ),
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await (weighInsReady == null ? tester.pumpAndSettle() : tester.pump());
}

/// The weigh-in of today in the weight chart.
double? _todaysWeighIn(WidgetTester tester) {
  final chart = tester.widget<ProgressDayChart>(
    find.descendant(
      of: find.byKey(ProgressWeightSection.sectionKey),
      matching: find.byType(ProgressDayChart),
    ),
  );
  return chart.days.last.dot;
}

/// The trend weight at the head of the weight section.
String _trendWeight(WidgetTester tester) {
  return tester
      .widget<ProgressSectionHeader>(
        find.descendant(
          of: find.byKey(ProgressWeightSection.sectionKey),
          matching: find.byType(ProgressSectionHeader),
        ),
      )
      .value;
}

void main() {
  testWidgets('Fortschritt shows the action button with its word', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpProgressTab(tester);

    expect(find.byKey(HomeBottomNavBar.actionKey), findsOneWidget);
    expect(find.text('LOG'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(HomeBottomNavBar.actionKey)),
      isSemantics(label: 'Log', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('the action panel opens the weight entry for today', (
    tester,
  ) async {
    await _pumpProgressTab(tester);

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    expect(find.byType(HomeActionPanel), findsOneWidget);
    await tester.tap(find.byKey(ProgressActionKeys.weigh));
    await tester.pumpAndSettle();

    expect(find.text('Set weight for Sep 24, 2026'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(DiaryWeightDialogKeys.weightDialogField),
    );
    expect(field.controller!.text, '82.0');
  });

  testWidgets('a double tap while the weights load opens one weight entry '
      '(#703)', (tester) async {
    final weighIns = Completer<void>();
    await _pumpProgressTab(tester, weighInsReady: weighIns.future);

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    // The loading charts spin, so the panel motion is pumped by time.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(ProgressActionKeys.weigh));
    await tester.tap(find.byKey(ProgressActionKeys.weigh));
    await tester.pump();
    weighIns.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(DiaryWeightDialogKeys.weightDialogField), findsOneWidget);
  });

  testWidgets('a saved weight shows in the chart and the goal right away', (
    tester,
  ) async {
    await _pumpProgressTab(tester);
    // The kg to the goal weight, which follow the trend weight.
    String? remaining() => tester
        .widget<Text>(
          find.descendant(
            of: find.byKey(ProgressGoalCard.cardKey),
            matching: find.textContaining('to go'),
          ),
        )
        .data;
    expect(_todaysWeighIn(tester), 82.0);
    final trendBefore = _trendWeight(tester);
    final remainingBefore = remaining();

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
    // A new weighing joins the day's 82.0, so the day counts their median.
    expect(_todaysWeighIn(tester), closeTo(81.2, 0.001));
    expect(_trendWeight(tester), isNot(trendBefore));
    expect(remaining(), isNot(remainingBefore));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the action panel adds a progress photo', (tester) async {
    final photos = FakeProgressPhotoRepository(
      pickedImage: Uint8List.fromList(<int>[1, 2, 3]),
    );
    addTearDown(photos.dispose);
    await _pumpProgressTab(tester, photos: photos);

    await tester.tap(find.byKey(HomeBottomNavBar.actionKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProgressActionKeys.photo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProgressPhotoCaptureSheet.cameraKey));
    await tester.pumpAndSettle();

    expect(photos.photos, hasLength(1));
    expect(find.byType(ProgressPhotoCaptureSheet), findsNothing);
    expect(find.text('Photo saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
