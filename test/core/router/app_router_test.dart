import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';

void main() {
  testWidgets('shows welcome screen on app start', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const YAMT(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });

  testWidgets('redirects root path to welcome', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const YAMT()),
    );
    await tester.pumpAndSettle();

    router.go(AppRoutes.root);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.welcome);
    expect(find.text('Yet Another Meal Tracker'), findsOneWidget);
  });
}
