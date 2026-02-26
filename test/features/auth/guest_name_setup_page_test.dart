import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/features/auth/guest_name_setup_page.dart';
import 'package:yamt/features/auth/provider/auth_repository.dart';
import 'package:yamt/l10n/app_localizations.dart';
import '../../helpers/fake_auth_repository.dart';

class _DelayedGuestNameRepository extends FakeAuthRepository {
  _DelayedGuestNameRepository(this.completer);

  final Completer<void> completer;

  @override
  Future<void> updateCurrentUserDisplayName({
    required String displayName,
  }) async {
    guestNameUpdateCalls++;
    lastGuestDisplayName = displayName;
    await completer.future;
  }
}

Widget _wrapWithRouter(FakeAuthRepository repository) {
  final router = GoRouter(
    initialLocation: AppRoutes.guestNameSetup,
    routes: [
      GoRoute(
        path: AppRoutes.guestNameSetup,
        builder: (context, state) => const GuestNameSetupPage(),
      ),
      GoRoute(
        path: AppRoutes.homeInventory,
        builder: (context, state) => const Scaffold(body: Text('Inventory')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('shows inline error when name is empty', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a display name.'), findsOneWidget);
    expect(repository.guestNameUpdateCalls, 0);
  });

  testWidgets('submits guest name to repository', (tester) async {
    final repository = FakeAuthRepository();
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repository.guestNameUpdateCalls, 1);
    expect(repository.lastGuestDisplayName, 'Guest Wlad');
    expect(find.text('Inventory'), findsNothing);
  });

  testWidgets('ignores repeated submit while request is loading', (
    tester,
  ) async {
    final completer = Completer<void>();
    final repository = _DelayedGuestNameRepository(completer);
    await tester.pumpWidget(_wrapWithRouter(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Guest Wlad');
    await tester.tap(find.byType(TextField));
    await tester.pump();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(repository.guestNameUpdateCalls, 1);
    completer.complete();
    await tester.pumpAndSettle();
  });
}
