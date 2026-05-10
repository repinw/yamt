import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';

void main() {
  testWidgets('isCompactViewport is true below compact breakpoint', (
    tester,
  ) async {
    late bool isCompact;

    await tester.pumpWidget(
      _buildProbe(
        size: const Size(359, 800),
        builder: (context) {
          isCompact = isCompactViewport(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(isCompact, isTrue);
  });

  testWidgets('responsivePageHorizontalPadding uses compact spacing', (
    tester,
  ) async {
    late double padding;

    await tester.pumpWidget(
      _buildProbe(
        size: const Size(320, 800),
        builder: (context) {
          padding = responsivePageHorizontalPadding(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(padding, AppSpacing.md);
  });

  testWidgets('responsivePageHorizontalPadding uses regular spacing', (
    tester,
  ) async {
    late double padding;

    await tester.pumpWidget(
      _buildProbe(
        size: const Size(360, 800),
        builder: (context) {
          padding = responsivePageHorizontalPadding(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(padding, AppSpacing.xl);
  });

  testWidgets('responsivePagePadding applies responsive horizontal inset', (
    tester,
  ) async {
    late EdgeInsets padding;

    await tester.pumpWidget(
      _buildProbe(
        size: const Size(320, 800),
        builder: (context) {
          padding = responsivePagePadding(
            context,
            top: AppSpacing.lg,
            bottom: AppSpacing.xl,
          );
          return const SizedBox.shrink();
        },
      ),
    );

    expect(
      padding,
      const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
    );
  });

  testWidgets('responsiveCardPadding uses compact inset on narrow screens', (
    tester,
  ) async {
    late EdgeInsets padding;

    await tester.pumpWidget(
      _buildProbe(
        size: const Size(320, 800),
        builder: (context) {
          padding = responsiveCardPadding(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(padding, const EdgeInsets.all(AppSpacing.lg));
  });

  testWidgets('responsiveCardPadding uses regular inset on wider screens', (
    tester,
  ) async {
    late EdgeInsets padding;

    await tester.pumpWidget(
      _buildProbe(
        size: const Size(430, 800),
        builder: (context) {
          padding = responsiveCardPadding(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(padding, const EdgeInsets.all(AppSpacing.xl));
  });

  testWidgets('homeShellPageBottomPadding includes shell clearance', (
    tester,
  ) async {
    late double padding;

    await tester.pumpWidget(
      _buildProbe(
        size: const Size(430, 800),
        builder: (context) {
          padding = homeShellPageBottomPadding(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(
      padding,
      AppSizes.homeShellBottomBarClearance + AppSpacing.xxxxl,
    );
  });
}

Widget _buildProbe({
  required Size size,
  required WidgetBuilder builder,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Builder(builder: builder),
    ),
  );
}
