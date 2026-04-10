import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card.dart';

void main() {
  const labelStyle = TextStyle(fontSize: 12);

  test('doesCaloriesSummaryTextFitWidth detects fitting text', () {
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'FETT',
        style: labelStyle,
        maxWidth: 200,
      ),
      isTrue,
    );
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'KOHlenhydrate',
        style: labelStyle,
        maxWidth: 8,
      ),
      isFalse,
    );
  });

  test('resolveMacroLabelForWidth keeps the full label when it fits', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 200,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, 'KOHLENHYDRATE');
  });

  test('resolveMacroLabelForWidth truncates and appends a dot', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 40,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, isNot('KOHLENHYDRATE'));
    expect(resolvedLabel, endsWith('.'));
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: 'KOHLENHYDRATE',
        style: labelStyle,
        maxWidth: 40,
      ),
      isFalse,
    );
    expect(
      doesCaloriesSummaryTextFitWidth(
        text: resolvedLabel,
        style: labelStyle,
        maxWidth: 40,
      ),
      isTrue,
    );
  });

  test('resolveMacroLabelForWidth falls back to first letter and dot', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: 'KOHLENHYDRATE',
      style: labelStyle,
      maxWidth: 1,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, 'K.');
  });

  test('resolveMacroLabelForWidth returns empty string for empty labels', () {
    final resolvedLabel = resolveMacroLabelForWidth(
      label: '',
      style: labelStyle,
      maxWidth: 40,
      textDirection: ui.TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );

    expect(resolvedLabel, isEmpty);
  });
}
