import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';

import '../../features/calories/support/fake_calories_repositories.dart';

class _MockUser extends Mock implements User {}

const _routerTransitionDuration = Duration(milliseconds: 350);

Future<void> _pumpRouterTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_routerTransitionDuration);
}

ProviderContainer _createContainerWithAuth(Stream<User?> authStream) {
  final calorieLogRepository = FakeCalorieLogRepository();
  final calorieSettingsRepository = FakeCalorieSettingsRepository();
  final container = ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith((ref) => authStream),
      calorieLogRepositoryProvider.overrideWithValue(calorieLogRepository),
      calorieSettingsRepositoryProvider.overrideWithValue(
        calorieSettingsRepository,
      ),
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
}) {
  final user = _MockUser();
  when(() => user.uid).thenReturn(uid);
  when(() => user.isAnonymous).thenReturn(false);
  when(() => user.displayName).thenReturn(displayName);
  when(() => user.email).thenReturn(email);
  return user;
}

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

  testWidgets('switches home tabs and updates route path', (tester) async {
    final user = _authenticatedUser();

    final container = _createContainerWithAuth(Stream<User?>.value(user));

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);
    expect(router.state.uri.path, AppRoutes.homeInventory);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Inventory'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeShopping);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Shopping')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeCalories);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Calories')),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.settings));
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettings);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Settings')),
      findsOneWidget,
    );
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);

    await tester.tap(find.text('Account').first);
    await _pumpRouterTransition(tester);
    expect(router.state.uri.path, AppRoutes.homeSettingsAccount);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('redirects to welcome after logout from a home route', (
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

    authController.add(_authenticatedUser());
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(
      container.read(appRouterProvider).state.uri.path,
      AppRoutes.homeInventory,
    );

    authController.add(null);
    await tester.pump();
    await _pumpRouterTransition(tester);

    expect(container.read(appRouterProvider).state.uri.path, AppRoutes.welcome);
  });

  testWidgets('route-level redirects for root and home routes are configured', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
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

  testWidgets('calorie entry routes open full-screen editor pages', (
    tester,
  ) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await _pumpRouterTransition(tester);

    final router = container.read(appRouterProvider);

    router.go(AppRoutes.homeCaloriesEntryCreate);
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);
    expect(find.text('Add calorie entry'), findsOneWidget);
    expect(find.byKey(CalorieEntryEditorKeys.nameField), findsOneWidget);

    router.go(AppRoutes.homeCaloriesEntryEditPath('missing-entry'));
    await _pumpRouterTransition(tester);
    await _pumpRouterTransition(tester);
    expect(find.text('Edit calorie entry'), findsOneWidget);
    expect(find.text('Entry not found.'), findsOneWidget);
  });

  testWidgets('barcode scan route is registered on app router', (tester) async {
    final container = _createContainerWithAuth(
      Stream<User?>.value(_authenticatedUser()),
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
    final barcodeRoute = routes.firstWhere(
      (route) => route.path == AppRoutes.homeCaloriesBarcodeScan,
    );

    expect(barcodeRoute.path, AppRoutes.homeCaloriesBarcodeScan);
  });
}
