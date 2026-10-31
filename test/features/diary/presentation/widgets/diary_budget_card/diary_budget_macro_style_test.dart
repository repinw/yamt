import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';

const _white = Color(0xFFFFFFFF);

Future<BuildContext> _context(WidgetTester tester, ThemeData theme) async {
  await tester.pumpWidget(Theme(data: theme, child: const SizedBox()));
  return tester.element(find.byType(SizedBox));
}

void main() {
  testWidgets('light macro text reaches 4.6:1 on the card and on white', (
    tester,
  ) async {
    final context = await _context(tester, AppTheme.light());
    final card = FoodLabelColors.of(context).card;

    for (final kind in DiaryBudgetMacroKind.values) {
      final text = diaryBudgetMacroTextColor(
        context,
        diaryBudgetMacroColor(context, kind),
      );
      expect(
        contrastRatio(text, card),
        greaterThanOrEqualTo(4.6),
        reason: '${kind.name} on the card',
      );
      expect(
        contrastRatio(text, _white),
        greaterThanOrEqualTo(4.6),
        reason: '${kind.name} on white',
      );
    }
  });

  testWidgets('light protein and carbs keep the color of the lightness cap', (
    tester,
  ) async {
    final context = await _context(tester, AppTheme.light());

    for (final kind in [
      DiaryBudgetMacroKind.protein,
      DiaryBudgetMacroKind.carbs,
    ]) {
      final macro = diaryBudgetMacroColor(context, kind);
      final hsl = HSLColor.fromColor(macro);
      expect(
        diaryBudgetMacroTextColor(context, macro),
        hsl
            .withLightness(
              math.min(hsl.lightness, AppFoodLabel.lightLabelMaxLightness),
            )
            .toColor(),
        reason: kind.name,
      );
    }
  });

  testWidgets('dark macro text is the macro color', (tester) async {
    final context = await _context(tester, AppTheme.dark());

    for (final kind in DiaryBudgetMacroKind.values) {
      final macro = diaryBudgetMacroColor(context, kind);
      expect(
        diaryBudgetMacroTextColor(context, macro),
        macro,
        reason: kind.name,
      );
    }
  });
}
