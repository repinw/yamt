import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Accent color of the macro [kind].
Color diaryBudgetMacroColor(BuildContext context, DiaryBudgetMacroKind kind) {
  final accents = MetricAccentColors.of(context);
  return switch (kind) {
    DiaryBudgetMacroKind.protein => accents.protein,
    DiaryBudgetMacroKind.carbs => accents.carbs,
    DiaryBudgetMacroKind.fat => accents.fat,
  };
}

/// [macroColor] as text color: on light paper, bright macro colors are
/// darkened to the lightness cap, and a color that still does not read on
/// the card, such as the fat yellow, further until it does. Colors the user
/// picked stay as they are.
Color diaryBudgetMacroTextColor(BuildContext context, Color macroColor) {
  if (Theme.of(context).brightness != Brightness.light ||
      MetricAccentColors.of(context).macrosAsPicked) {
    return macroColor;
  }
  final card = FoodLabelColors.of(context).card;
  final hsl = HSLColor.fromColor(macroColor);
  var text = hsl.withLightness(
    math.min(hsl.lightness, AppFoodLabel.lightLabelMaxLightness),
  );
  while (text.lightness >= AppFoodLabel.lightLabelLightnessStep &&
      contrastRatio(text.toColor(), card) <
          AppFoodLabel.lightLabelMinContrast) {
    text = text.withLightness(
      text.lightness - AppFoodLabel.lightLabelLightnessStep,
    );
  }
  return text.toColor();
}

/// Name of the macro [kind].
String diaryBudgetMacroLabel(
  AppLocalizations l10n,
  DiaryBudgetMacroKind kind,
) => switch (kind) {
  DiaryBudgetMacroKind.protein => l10n.caloriesProteinLabel,
  DiaryBudgetMacroKind.carbs => l10n.diaryBudgetCarbsLabel,
  DiaryBudgetMacroKind.fat => l10n.caloriesFatLabel,
};

/// The grams of [macro] as the budget card shows them: left, or over with
/// a plus; eaten with the counted plans on a pause day or with [showEaten].
String diaryBudgetMacroValue(
  AppLocalizations l10n,
  DiaryBudgetMacro macro, {
  required bool showEaten,
  required bool isPauseDay,
  required NumberFormat numberFormat,
}) {
  final counted = macro.eaten + macro.planned;
  final left = (macro.target - counted).round();
  String grams(num value) => numberFormat.format(value.round());

  return isPauseDay || showEaten
      ? l10n.diaryBudgetMacroLeft(grams(counted))
      : left < 0
      ? l10n.diaryBudgetMacroOver(grams(-left))
      : l10n.diaryBudgetMacroLeft(grams(left));
}
