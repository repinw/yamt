import 'package:flutter/material.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';

/// Collapsed view of a meal card, presenting no entry rows until expanded.
class DiaryCollapsedMealBody extends StatelessWidget {
  /// Creates the collapsed meal body.
  const DiaryCollapsedMealBody({
    required this.section,
    this.onTapEntry,
    super.key,
  });

  /// The meal section displayed.
  final DiaryMealSection section;

  /// Optional callback retained for compatibility.
  final ValueChanged<DiaryMealEntry>? onTapEntry;

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink(
      key: DiaryMealsSectionKeys.collapsedEmpty(section.mealType),
    );
  }
}
