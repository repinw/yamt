import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';

void main() {
  group('MetricAccentColors', () {
    test('copyWith replaces every supplied color and keeps omitted values', () {
      const original = MetricAccentColors(
        activity: Color(0xFF000001),
        activityDark: Color(0xFF000002),
        activityText: Color(0xFF000003),
        activityTextDark: Color(0xFF000004),
        weight: Color(0xFF000005),
        carbs: Color(0xFF000006),
        protein: Color(0xFF000007),
        fat: Color(0xFF000008),
        meal: Color(0xFF000009),
        today: Color(0xFF00000A),
        heart: Color(0xFF00000B),
        heartDark: Color(0xFF00000C),
        steps: Color(0xFF00000D),
        stepsDark: Color(0xFF00000E),
      );

      final unchanged = original.copyWith();
      expect(unchanged.activity, original.activity);
      expect(unchanged.stepsDark, original.stepsDark);

      final changed = original.copyWith(
        activity: const Color(0xFF100001),
        activityDark: const Color(0xFF100002),
        activityText: const Color(0xFF100003),
        activityTextDark: const Color(0xFF100004),
        weight: const Color(0xFF100005),
        carbs: const Color(0xFF100006),
        protein: const Color(0xFF100007),
        fat: const Color(0xFF100008),
        meal: const Color(0xFF100009),
        today: const Color(0xFF10000A),
        heart: const Color(0xFF10000B),
        heartDark: const Color(0xFF10000C),
        steps: const Color(0xFF10000D),
        stepsDark: const Color(0xFF10000E),
      );

      expect(changed.activity, const Color(0xFF100001));
      expect(changed.activityDark, const Color(0xFF100002));
      expect(changed.activityText, const Color(0xFF100003));
      expect(changed.activityTextDark, const Color(0xFF100004));
      expect(changed.weight, const Color(0xFF100005));
      expect(changed.carbs, const Color(0xFF100006));
      expect(changed.protein, const Color(0xFF100007));
      expect(changed.fat, const Color(0xFF100008));
      expect(changed.meal, const Color(0xFF100009));
      expect(changed.today, const Color(0xFF10000A));
      expect(changed.heart, const Color(0xFF10000B));
      expect(changed.heartDark, const Color(0xFF10000C));
      expect(changed.steps, const Color(0xFF10000D));
      expect(changed.stepsDark, const Color(0xFF10000E));
    });

    test('lerp interpolates every color field', () {
      const begin = MetricAccentColors(
        activity: Color(0xFF000000),
        activityDark: Color(0xFF100000),
        activityText: Color(0xFF200000),
        activityTextDark: Color(0xFF300000),
        weight: Color(0xFF400000),
        carbs: Color(0xFF500000),
        protein: Color(0xFF600000),
        fat: Color(0xFF700000),
        meal: Color(0xFF800000),
        today: Color(0xFF900000),
        heart: Color(0xFFA00000),
        heartDark: Color(0xFFB00000),
        steps: Color(0xFFC00000),
        stepsDark: Color(0xFFD00000),
      );
      const end = MetricAccentColors(
        activity: Color(0xFFFFFFFF),
        activityDark: Color(0xFFFFF0F0),
        activityText: Color(0xFFFFE0E0),
        activityTextDark: Color(0xFFFFD0D0),
        weight: Color(0xFFFFC0C0),
        carbs: Color(0xFFFFB0B0),
        protein: Color(0xFFFFA0A0),
        fat: Color(0xFFFF9090),
        meal: Color(0xFFFF8080),
        today: Color(0xFFFF7070),
        heart: Color(0xFFFF6060),
        heartDark: Color(0xFFFF5050),
        steps: Color(0xFFFF4040),
        stepsDark: Color(0xFFFF3030),
      );

      final result = begin.lerp(end, 0.5);

      expect(result.activity, Color.lerp(begin.activity, end.activity, 0.5));
      expect(
        result.activityDark,
        Color.lerp(begin.activityDark, end.activityDark, 0.5),
      );
      expect(
        result.activityText,
        Color.lerp(begin.activityText, end.activityText, 0.5),
      );
      expect(
        result.activityTextDark,
        Color.lerp(begin.activityTextDark, end.activityTextDark, 0.5),
      );
      expect(result.weight, Color.lerp(begin.weight, end.weight, 0.5));
      expect(result.carbs, Color.lerp(begin.carbs, end.carbs, 0.5));
      expect(result.protein, Color.lerp(begin.protein, end.protein, 0.5));
      expect(result.fat, Color.lerp(begin.fat, end.fat, 0.5));
      expect(result.meal, Color.lerp(begin.meal, end.meal, 0.5));
      expect(result.today, Color.lerp(begin.today, end.today, 0.5));
      expect(result.heart, Color.lerp(begin.heart, end.heart, 0.5));
      expect(
        result.heartDark,
        Color.lerp(begin.heartDark, end.heartDark, 0.5),
      );
      expect(result.steps, Color.lerp(begin.steps, end.steps, 0.5));
      expect(result.stepsDark, Color.lerp(begin.stepsDark, end.stepsDark, 0.5));
    });

    test('lerp returns itself for unrelated extensions', () {
      expect(
        MetricAccentColors.fallback.lerp(null, 0.5),
        same(MetricAccentColors.fallback),
      );
    });
  });
}
