import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/domain/auth_profile_setup_preferences.dart';
import 'package:yamt/features/auth/provider/'
    'auth_profile_setup_status_provider.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/burn_week_live_sync_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_goal_onboarding_completed_provider.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_batch_flow_controller.dart';
import 'package:yamt/features/scanner/provider/receipt_capture_flow_controller.dart';

import '../../features/calories/support/fake_calories_repositories.dart';
import '../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

const _routerTransitionDuration = Duration(milliseconds: 350);

class _MockUserMetadata extends Mock implements UserMetadata {}

Future<void> _pumpRouterTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_routerTransitionDuration);
}

UserMetadata _userMetadata({required bool isFirstSignIn}) {
  final metadata = _MockUserMetadata();
  final createdAt = DateTime.utc(2026, 1, 1, 9);
  final lastSignInAt = isFirstSignIn
      ? createdAt
      : createdAt.add(const Duration(days: 7));
  when(() => metadata.creationTime).thenReturn(createdAt);
  when(() => metadata.lastSignInTime).thenReturn(lastSignInAt);
  return metadata;
}

ProviderContainer _createContainerWithAuth(
  Stream<User?> authStream, {
  Set<String> completedProfileSetupUserIds = const <String>{},
  Set<String> completedCalorieGoalOnboardingUserIds = const <String>{},
  CalorieGoalSettings initialCalorieSettings =
      const CalorieGoalSettings.empty(),
}) {
  final calorieLogRepository = FakeCalorieLogRepository();
  final calorieSettingsRepository = FakeCalorieSettingsRepository(
    initialSettings: initialCalorieSettings,
  );
  final broadcastAuthStream = authStream.isBroadcast
      ? authStream
      : authStream.asBroadcastStream();
  final appPreferences = MemoryAppPreferences(
    completedProfileSetupUserIds: completedProfileSetupUserIds,
    completedCalorieGoalOnboardingUserIds:
        completedCalorieGoalOnboardingUserIds,
  );
  final firebaseAuth = _MockFirebaseAuth();
  when(() => firebaseAuth.currentUser).thenReturn(null);
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(appPreferences),
      authStateChangesProvider.overrideWith((ref) => broadcastAuthStream),
      firebaseAuthProvider.overrideWithValue(firebaseAuth),
      calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
      burnWeekLiveSyncProvider.overrideWith((ref) => null),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(calorieLogRepository.dispose);
  addTearDown(calorieSettingsRepository.dispose);
  return container;
}

_MockUser _authenticatedUser({
  String uid = 'uid-123',
  String? displayName = 'Jane Doe',
  String? email = 'jane@example.com',
  bool isFirstSignIn = false,
}) {
  final user = _MockUser();
  final metadata = _userMetadata(isFirstSignIn: isFirstSignIn);
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(email);
  when(() => user.metadata).thenReturn(metadata);
  return user;
}

_MockUser _guestUser({
  String uid = 'guest-123',
  String? displayName,
  bool isFirstSignIn = true,
}) {
  final user = _MockUser();
  final metadata = _userMetadata(isFirstSignIn: isFirstSignIn);
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(true);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(null);
  when(() => user.metadata).thenReturn(metadata);
  return user;
}

const _inventoryBackedCreateArgs = CalorieEntryCreateArgs(
  prefilledProfile: null,
  inventoryContext: CalorieInventoryCreateContext(
    inventoryItemId: 'inventory-1',
    foodFingerprint: 'milk',
    globalFoodItemId: 'off-milk',
    pendingConsumptionId: 'pending-1',
    inventoryAmountToRestore: 2,
    itemName: 'Milk',
    itemBrand: null,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
  ),
);

@Dependencies([
  appRouter,
  InventoryItemsController,
  ReceiptCaptureFlowController,
  ReceiptBatchFlowController,
])
void main() {
  testWidgets('shows splash while auth state is loading', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.fromFuture(
        Future<User?>.delayed(const Duration(milliseconds: 50), () => null),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 60));
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });

  testWidgets('keeps redirecting to splash while auth stream has not emitted', (
    tester,
  ) async {
    final authController = StreamController<User?>();
    final container = _createContainerWithAuth(authController.stream);
    addTearDown(() {
      unawaited(authController.close());
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);

    container.read(appRouterProvider).go(AppRoutes.home);
    await tester.pump();

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.splash);

    authController.add(null);
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    container.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('redirects root path to welcome', (tester) async {
    final container = _createContainerWithAuth(Stream<User?>.value(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    container.read(appRouterProvider).go(AppRoutes.root);
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });

  testWidgets('redirects unauthenticated user away from home', (tester) async {
    final container = _createContainerWithAuth(Stream<User?>.value(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    container.read(appRouterProvider).go(AppRoutes.home);
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
  });

  testWidgets('redirects authenticated user away from welcome', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );

    container.read(appRouterProvider).go(AppRoutes.welcome);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );
  });

  testWidgets('redirects anonymous user without name to guest setup', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_guestUser()),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
    expect(find.text('Set your guest name'), findsOneWidget);
  });

  testWidgets('named anonymous user without setup marker stays in setup', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_guestUser(displayName: 'Guest Name')),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
  });

  testWidgets('named anonymous user with setup marker is routed to home', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_guestUser(displayName: 'Guest Name')),
      completedProfileSetupUserIds: {'guest-123'},
      completedCalorieGoalOnboardingUserIds: {'guest-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );
  });

  testWidgets('redirects freshly created named user to setup page', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(
        _authenticatedUser(
          uid: 'fresh-user',
          displayName: 'Fresh Google User',
          isFirstSignIn: true,
        ),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
  });

  testWidgets('skips setup for fresh user after setup completion marker', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(
        _authenticatedUser(
          uid: 'fresh-user',
          displayName: 'Fresh Google User',
          isFirstSignIn: true,
        ),
      ),
      completedProfileSetupUserIds: {'fresh-user'},
      completedCalorieGoalOnboardingUserIds: {'fresh-user'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );
  });

  testWidgets(
    'redirects authenticated user without calorie onboarding to calorie setup',
    (tester) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(_authenticatedUser()),
        completedProfileSetupUserIds: {'uid-123'},
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );
      expect(find.text('Set your calorie goal'), findsOneWidget);
    },
  );

  testWidgets('saving calorie onboarding redirects to home', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.calorieGoalSetup,
    );

    for (var index = 0; index < 6; index += 1) {
      await tester.ensureVisible(
        find.byKey(CalorieGoalCalculatorSheetKeys.nextButton),
      );
      await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.nextButton));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(
      find.byKey(CalorieGoalCalculatorSheetKeys.saveButton),
    );
    await tester.tap(
      find.byKey(CalorieGoalCalculatorSheetKeys.goalStartNowOption),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(CalorieGoalCalculatorSheetKeys.todayTrackingExactOption),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(CalorieGoalCalculatorSheetKeys.saveButton),
    );
    await tester.tap(find.byKey(CalorieGoalCalculatorSheetKeys.saveButton));
    await tester.pump();
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );
  });

  testWidgets('existing calorie goal marks onboarding as completed', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      initialCalorieSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 2, 25, 10),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );
    expect(
      container
          .read(appPreferencesProvider)
          .getStringSync(calorieGoalOnboardingKeyForUser('uid-123')),
      calorieGoalOnboardingCompletedValue,
    );
  });

  testWidgets('redirects returning named user without setup marker to setup', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(
        _authenticatedUser(
          uid: 'returning-user',
          displayName: 'Returning Google User',
        ),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
  });

  testWidgets('stays on guest setup after name update without setup marker', (
    tester,
  ) async {
    final authController = StreamController<User?>();
    final container = _createContainerWithAuth(authController.stream);
    addTearDown(() {
      unawaited(authController.close());
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pump();

    authController.add(_guestUser());
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );

    authController.add(_guestUser(displayName: 'Guest Name'));
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.guestNameSetup,
    );
  });

  testWidgets(
    'moves from guest setup to calorie setup and then home via markers',
    (tester) async {
      final authController = StreamController<User?>();
      final container = _createContainerWithAuth(authController.stream);
      addTearDown(() {
        unawaited(authController.close());
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await tester.pump();

      authController.add(_authenticatedUser(uid: 'setup-user'));
      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.guestNameSetup,
      );

      await container
          .read(appPreferencesProvider)
          .setString(
            AuthProfileSetupPreferences.keyForUser('setup-user'),
            AuthProfileSetupPreferences.completedValue,
          );
      container.invalidate(authProfileSetupCompletedProvider);

      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.calorieGoalSetup,
      );

      await container
          .read(appPreferencesProvider)
          .setString(
            calorieGoalOnboardingKeyForUser('setup-user'),
            calorieGoalOnboardingCompletedValue,
          );
      container.invalidate(calorieGoalOnboardingCompletedProvider);

      await tester.pump();
      await _pumpRouterTransition(tester);

      expect(
        container.read(appRouterProvider).state.uri.path,
        AppRoutes.homeInventory,
      );
    },
  );

  testWidgets('navigates between home destinations and updates route path', (
    tester,
  ) async {
    final user = _authenticatedUser();

    final container = _createContainerWithAuth(
      Stream<User?>.value(user),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.homeInventory);
    expect(find.text('My inventory'), findsOneWidget);
    expect(find.text('STATISTICS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.insights_rounded).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.state.uri.path, AppRoutes.homeStatistics);
    expect(find.text('MVP note'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.inventory_2_rounded).hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(router.state.uri.path, AppRoutes.homeInventory);

    await tester.tap(find.byIcon(Icons.shopping_cart_rounded).hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeShopping);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).hitTestable());
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeInventory);

    router.go(AppRoutes.homeCalories);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeCalories);
    expect(find.text('Heute'), findsOneWidget);

    router.go(AppRoutes.homeSettings);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettings);
    expect(find.text('Settings'), findsOneWidget);

    router.go(AppRoutes.homeSettingsAccount);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettingsAccount);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('inventory clipboard button opens templates page', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.homeInventory);

    await tester.tap(find.byIcon(Icons.bookmarks_rounded).hitTestable());
    await _pumpRouterTransition(tester);

    expect(router.state.uri.path, AppRoutes.homeInventoryTemplates);
    expect(find.text('Templates'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('route-level redirects for root and home routes are configured', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    final context = tester.element(find.byType(YAMT));
    final routes = router.configuration.routes.whereType<GoRoute>().toList();
    final rootRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.root,
    );
    final homeRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.home,
    );

    expect(
      rootRoute.redirect?.call(context, router.state),
      AppRoutes.homeInventory,
    );
    expect(
      homeRoute.redirect?.call(context, router.state),
      AppRoutes.homeInventory,
    );
  });

  testWidgets('appRouterProvider supports overrideWithValue', (tester) async {
    final stubRouter = GoRouter(
      routes: [
        GoRoute(
          path: AppRoutes.root,
          builder: (context, state) => const SizedBox.shrink(),
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [appRouterProvider.overrideWithValue(stubRouter)],
    );
    addTearDown(container.dispose);

    expect(container.read(appRouterProvider), same(stubRouter));
  });

  testWidgets(
    'inventory-backed create opens a page and details route opens a sheet',
    (
      tester,
    ) async {
      final container = _createContainerWithAuth(
        Stream<User?>.value(_authenticatedUser()),
        completedProfileSetupUserIds: {'uid-123'},
        completedCalorieGoalOnboardingUserIds: {'uid-123'},
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const YAMT()),
      );
      await _pumpRouterTransition(tester);

      final router = container.read(appRouterProvider)
        ..go(
          AppRoutes.homeCaloriesEntryCreate,
          extra: _inventoryBackedCreateArgs,
        );
      await _pumpRouterTransition(tester);
      await _pumpRouterTransition(tester);
      expect(find.text('Add calorie entry'), findsOneWidget);
      expect(find.byKey(CalorieEntryEditorKeys.nameField), findsOneWidget);

      router.go(AppRoutes.homeCaloriesEntryCreate);
      await _pumpRouterTransition(tester);
      expect(router.state.uri.path, AppRoutes.homeInventory);

      router.go(AppRoutes.homeCaloriesEntryDetailsPath('missing-entry'));
      await _pumpRouterTransition(tester);
      await _pumpRouterTransition(tester);
      expect(find.text('Calorie entry details'), findsOneWidget);
      expect(find.text('Entry not found.'), findsOneWidget);
      expect(find.byType(ModalBarrier), findsOneWidget);
    },
  );

  testWidgets('statistics weight route is registered on app router', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final routes = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .toList();
    final trendsRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeStatisticsWeight,
    );

    expect(trendsRoute.path, AppRoutes.homeStatisticsWeight);
  });

  testWidgets('inventory manual add route is registered on app router', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final routes = container
        .read(appRouterProvider)
        .configuration
        .routes
        .whereType<GoRoute>()
        .toList();
    final manualAddRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeInventoryManualAdd,
    );

    expect(manualAddRoute.path, AppRoutes.homeInventoryManualAdd);
  });

  testWidgets('Burn Week mock route is reachable for authenticated user', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
      completedProfileSetupUserIds: {'uid-123'},
      completedCalorieGoalOnboardingUserIds: {'uid-123'},
      initialCalorieSettings: CalorieGoalSettings.single(
        dailyKcalGoal: 2200,
        calculatorProfile: null,
        effectiveDate: DateTime(2026, 4, 20),
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    container.read(appRouterProvider).go(AppRoutes.homeCaloriesBurnWeekMock);
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeCaloriesBurnWeekMock,
    );
    expect(find.text('Burn Week'), findsWidgets);
  });
}
