import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/app_cached_network_image.dart';
import 'package:yamt/features/scanner/presentation/widgets/product_candidate_thumbnail.dart';

void main() {
  group('ProductCandidateThumbnail', () {
    testWidgets('renders AppCachedNetworkImage when imageUrl is valid', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProductCandidateThumbnail(
              imageUrl: 'https://example.com/test.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(AppCachedNetworkImage), findsOneWidget);
    });

    testWidgets('renders fallback icon when imageUrl is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProductCandidateThumbnail()),
        ),
      );

      expect(find.byType(AppCachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('renders fallback icon when imageUrl is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProductCandidateThumbnail(imageUrl: '')),
        ),
      );

      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });
  });
}
