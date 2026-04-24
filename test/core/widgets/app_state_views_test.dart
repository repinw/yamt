import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/app_state_views.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('AppLoadingView renders centered progress indicator', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AppLoadingView()));

    expect(find.byType(Center), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppErrorRetryView renders message and invokes retry', (
    tester,
  ) async {
    var retryCount = 0;
    const retryKey = Key('retry');

    await tester.pumpWidget(
      _wrap(
        AppErrorRetryView(
          message: 'Could not load data.',
          retryLabel: 'Retry',
          retryButtonKey: retryKey,
          onRetry: () => retryCount += 1,
        ),
      ),
    );

    expect(find.text('Could not load data.'), findsOneWidget);
    expect(find.byKey(retryKey), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

    await tester.tap(find.byKey(retryKey));
    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('AppErrorRetryView supports custom error icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppErrorRetryView(
          message: 'Network unavailable.',
          retryLabel: 'Retry',
          icon: Icons.wifi_tethering_error_rounded,
          onRetry: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.wifi_tethering_error_rounded), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}
