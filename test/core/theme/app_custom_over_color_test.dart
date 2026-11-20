import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

void main() {
  const pickedSignal = Color(0xFF2E7D32);

  test('"over" stays the fixed orange in Individuell, light', () {
    final colors = AppCustomColors.copyOf(AppTheme.light())
        .withColor(AppCustomColor.signal, pickedSignal);

    final labels = AppTheme.custom(colors).extension<FoodLabelColors>()!;

    expect(labels.over, const Color(0xFFC85A08));
  });

  test('"over" stays the fixed orange in Individuell, dark', () {
    final colors = AppCustomColors.copyOf(AppTheme.dark())
        .withColor(AppCustomColor.signal, pickedSignal);

    final labels = AppTheme.custom(colors).extension<FoodLabelColors>()!;

    expect(labels.over, const Color(0xFFFF9A3C));
  });
}
