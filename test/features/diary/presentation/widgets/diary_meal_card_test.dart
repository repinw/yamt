import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/diary/domain/diary_meal_section.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meal_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  testWidgets('uses shared surface card styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(seedColor: Colors.green),
        home: Scaffold(
          body: DiaryMealCard(
            section: const DiaryMealSection(
              mealType: MealType.breakfast,
              totalKcal: 120,
              entries: [
                DiaryMealEntry(
                  id: 'oats',
                  mealType: MealType.breakfast,
                  name: 'Oats',
                  totalKcal: 120,
                  totalProtein: 8,
                  totalCarbs: 18,
                  totalFat: 4,
                ),
              ],
            ),
            isExpanded: false,
            onToggle: () {},
            onTapEntry: (_) {},
            onQuickAdd: (_) {},
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(DiaryMealCard));
    final colors = Theme.of(context).colorScheme;

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration == AppQuietSurfaces.cardDecoration(colors),
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding &&
            widget.padding == const EdgeInsets.all(AppSpacing.md),
      ),
      findsOneWidget,
    );
  });
}
