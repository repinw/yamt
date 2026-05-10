import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/auth/auth_ui_constants.dart';
import 'package:yamt/features/auth/widgets/auth_layout_metrics.dart';

void main() {
  group('AuthLayoutMetrics', () {
    test('uses fixed desktop metrics for wide layouts', () {
      final metrics = AuthLayoutMetrics.fromConstraints(
        maxWidth: 1200,
        maxHeight: 900,
        isWide: true,
      );

      expect(metrics.heroBadgeSize, AppAuthUi.heroBadgeSize);
      expect(metrics.heroIconSize, AppAuthUi.heroIconSize * 0.42);
      expect(metrics.cardPadding, AppAuthUi.cardPadding);
      expect(metrics.headerSpacing, AppSpacing.xxxl);
      expect(metrics.sectionSpacing, AppSpacing.xxxl);
      expect(metrics.footerSpacing, AppSpacing.xxl);
      expect(metrics.socialButtonHeight, AppAuthUi.socialButtonHeight);
      expect(metrics.centerContent, isTrue);
    });

    test('clamps compact layout scale for very small screens', () {
      final metrics = AuthLayoutMetrics.fromConstraints(
        maxWidth: 300,
        maxHeight: 500,
        isWide: false,
      );

      expect(metrics.heroBadgeSize, moreOrLessEquals(72.16));
      expect(metrics.heroIconSize, moreOrLessEquals(28.9296));
      expect(metrics.cardPadding.left, moreOrLessEquals(16.4));
      expect(metrics.cardPadding.top, moreOrLessEquals(16.4));
      expect(metrics.headerSpacing, moreOrLessEquals(16.4));
      expect(metrics.sectionSpacing, moreOrLessEquals(16.4));
      expect(metrics.footerSpacing, moreOrLessEquals(13.12));
      expect(metrics.socialButtonHeight, 48);
      expect(metrics.centerContent, isFalse);
    });

    test('keeps standard mobile layout at full scale', () {
      final metrics = AuthLayoutMetrics.fromConstraints(
        maxWidth: 420,
        maxHeight: 800,
        isWide: false,
      );

      expect(metrics.heroBadgeSize, AppAuthUi.heroBadgeSize);
      expect(metrics.heroIconSize, AppAuthUi.heroIconSize * 0.42);
      expect(metrics.cardPadding.left, AppSpacing.xxl);
      expect(metrics.cardPadding.top, AppSpacing.xxl);
      expect(metrics.headerSpacing, AppSpacing.xxl);
      expect(metrics.sectionSpacing, AppSpacing.xxl);
      expect(metrics.footerSpacing, AppSpacing.xl);
      expect(metrics.socialButtonHeight, AppAuthUi.socialButtonHeight);
      expect(metrics.centerContent, isTrue);
    });
  });
}
