import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/app.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('home shell shows app bar and tabs for authenticated user', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(_MockUser()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsAtLeastNWidgets(1));
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('inventory FAB opens receipt action sheet', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(_MockUser()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Scan receipt (camera)'), findsOneWidget);
    expect(find.text('Upload receipt (image/PDF)'), findsOneWidget);
  });

  testWidgets('non-inventory tabs show contextual snackbar', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream<User?>.value(_MockUser()),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Shopping action coming soon.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.local_fire_department_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Calories action coming soon.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Settings action coming soon.'), findsOneWidget);
  });
}
