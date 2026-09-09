import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/tdee_anticipation_calculator.dart';

void main() {
  group('TdeeAnticipationCalculator', () {
    final today = DateTime(2025, 3);

    test('returns null when targetWeightKg is null', () {
      final result = TdeeAnticipationCalculator.calculate(
        currentWeightKg: 85,
        targetWeightKg: null,
        goalMode: CalorieGoalMode.lose,
        recentWeightTrendKgPerDay: -0.1,
        startDate: today,
      );
      expect(result, isNull);
    });

    test('returns null when goalMode is maintain', () {
      final result = TdeeAnticipationCalculator.calculate(
        currentWeightKg: 85,
        targetWeightKg: 85,
        goalMode: CalorieGoalMode.maintain,
        recentWeightTrendKgPerDay: 0,
        startDate: today,
      );
      expect(result, isNull);
    });

    test('marks isAchieved when lose goal already reached', () {
      final result = TdeeAnticipationCalculator.calculate(
        currentWeightKg: 74.5,
        targetWeightKg: 75,
        goalMode: CalorieGoalMode.lose,
        recentWeightTrendKgPerDay: -0.08,
        startDate: today,
      );
      expect(result, isNotNull);
      expect(result!.isAchieved, isTrue);
      expect(result.daysRemaining, 0);
      expect(result.projectedDate, today);
    });

    test('marks isMovingAway when losing but weight is increasing', () {
      final result = TdeeAnticipationCalculator.calculate(
        currentWeightKg: 85,
        targetWeightKg: 80,
        goalMode: CalorieGoalMode.lose,
        recentWeightTrendKgPerDay: 0.05,
        startDate: today,
      );
      expect(result, isNotNull);
      expect(result!.isMovingAway, isTrue);
      expect(result.projectedDate, isNull);
    });

    test('projects future date accurately for weight loss', () {
      // 5 kg to lose at 0.1 kg / day = 50 days
      final result = TdeeAnticipationCalculator.calculate(
        currentWeightKg: 80,
        targetWeightKg: 75,
        goalMode: CalorieGoalMode.lose,
        recentWeightTrendKgPerDay: -0.1,
        startDate: today,
      );
      expect(result, isNotNull);
      expect(result!.isAchieved, isFalse);
      expect(result.isMovingAway, isFalse);
      expect(result.daysRemaining, 50);
      expect(result.projectedDate, today.add(const Duration(days: 50)));
      expect(result.trendSpeedKgPerWeek, closeTo(-0.7, 0.001));
      expect(result.projectionPoints, isNotEmpty);
      expect(result.projectionPoints.first.weightKg, 80);
      expect(result.projectionPoints.last.weightKg, 75);
    });

    test('projects future date accurately for weight gain', () {
      // 4 kg to gain at 0.05 kg / day = 80 days
      final result = TdeeAnticipationCalculator.calculate(
        currentWeightKg: 70,
        targetWeightKg: 74,
        goalMode: CalorieGoalMode.gain,
        recentWeightTrendKgPerDay: 0.05,
        startDate: today,
      );
      expect(result, isNotNull);
      expect(result!.isAchieved, isFalse);
      expect(result.daysRemaining, 80);
      expect(result.projectedDate, today.add(const Duration(days: 80)));
      expect(result.trendSpeedKgPerWeek, closeTo(0.35, 0.001));
    });
  });
}
