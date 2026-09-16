import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section.dart';

/// Places the diary meals section in the page's responsive scroll layout.
Widget buildDiaryPageMealsContent({
  required DateTime selectedDay,
  required double horizontalPadding,
  required double bottomPadding,
}) {
  return SliverPadding(
    padding: EdgeInsets.fromLTRB(
      horizontalPadding,
      0,
      horizontalPadding,
      bottomPadding,
    ),
    sliver: SliverList.builder(
      itemCount: 1,
      itemBuilder: (context, index) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.narrowContentMaxWidth,
            ),
            child: DiaryMealsSection(selectedDay: selectedDay),
          ),
        );
      },
    ),
  );
}
