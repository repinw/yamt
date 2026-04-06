import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';

Widget _buildHarness(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders CachedNetworkImage for a non-empty url', (tester) async {
    await tester.pumpWidget(
      _buildHarness(
        const SizedBox(
          width: 64,
          height: 64,
          child: AppCachedNetworkImage(
            imageUrl: 'https://images.example.com/item.jpg',
          ),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    final imageWidget = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(imageWidget.imageUrl, 'https://images.example.com/item.jpg');
  });

  testWidgets('empty url renders compact placeholder without icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        const SizedBox(
          width: 24,
          height: 24,
          child: AppCachedNetworkImage(imageUrl: ''),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.image_outlined), findsNothing);
  });

  testWidgets('empty url renders small placeholder icon below 56 px', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        const SizedBox(
          width: 48,
          height: 48,
          child: AppCachedNetworkImage(imageUrl: ''),
        ),
      ),
    );

    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.image_outlined));
    expect(iconWidget.size, 16);
  });

  testWidgets('empty url renders large placeholder icon at 56 px and above', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        const SizedBox(
          width: 80,
          height: 80,
          child: AppCachedNetworkImage(imageUrl: ''),
        ),
      ),
    );

    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.image_outlined));
    expect(iconWidget.size, 20);
  });

  testWidgets('empty url calls errorBuilder before CachedNetworkImage builds', (
    tester,
  ) async {
    Object? capturedError;

    await tester.pumpWidget(
      _buildHarness(
        SizedBox(
          width: 64,
          height: 64,
          child: AppCachedNetworkImage(
            imageUrl: '   ',
            errorBuilder: (context, error, stackTrace) {
              capturedError = error;
              return const Text('error');
            },
          ),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.text('error'), findsOneWidget);
    expect(capturedError, isA<Exception>());
    expect(capturedError.toString(), contains('Empty URL'));
  });
}
