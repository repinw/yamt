import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_expand_indicator.dart';

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required ThemeData theme,
  required bool isExpanded,
  required bool enabled,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: InventoryExpandIndicator(
            isExpanded: isExpanded,
            enabled: enabled,
            rotationKey: const Key('inventory_expand_indicator_rotation'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final theme = AppTheme.light(seedColor: AppColors.seed);

  testWidgets('uses expanded enabled colors and rotation', (tester) async {
    await _pumpIndicator(tester, theme: theme, isExpanded: true, enabled: true);

    final colors = theme.colorScheme;
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    final rotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('inventory_expand_indicator_rotation')),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.expand_more_rounded));

    expect(decoration.color, colors.primaryContainer.withValues(alpha: 0.72));
    expect(border.top.color, colors.primary.withValues(alpha: 0.24));
    expect(icon.color, colors.primary);
    expect(rotation.turns, 0.5);
  });

  testWidgets('uses collapsed enabled colors and rotation', (tester) async {
    await _pumpIndicator(
      tester,
      theme: theme,
      isExpanded: false,
      enabled: true,
    );

    final colors = theme.colorScheme;
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    final rotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('inventory_expand_indicator_rotation')),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.expand_more_rounded));

    expect(
      decoration.color,
      colors.surfaceContainerHigh.withValues(alpha: 0.82),
    );
    expect(border.top.color, colors.outlineVariant.withValues(alpha: 0.6));
    expect(icon.color, colors.onSurfaceVariant);
    expect(rotation.turns, 0);
  });

  testWidgets('uses expanded disabled colors and rotation', (tester) async {
    await _pumpIndicator(
      tester,
      theme: theme,
      isExpanded: true,
      enabled: false,
    );

    final colors = theme.colorScheme;
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    final rotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('inventory_expand_indicator_rotation')),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.expand_more_rounded));

    expect(
      decoration.color,
      colors.surfaceContainerHighest.withValues(alpha: 0.5),
    );
    expect(border.top.color, colors.outlineVariant.withValues(alpha: 0.32));
    expect(icon.color, colors.onSurfaceVariant.withValues(alpha: 0.55));
    expect(rotation.turns, 0.5);
  });

  testWidgets('uses collapsed disabled colors and rotation', (tester) async {
    await _pumpIndicator(
      tester,
      theme: theme,
      isExpanded: false,
      enabled: false,
    );

    final colors = theme.colorScheme;
    final container = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    final rotation = tester.widget<AnimatedRotation>(
      find.byKey(const Key('inventory_expand_indicator_rotation')),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.expand_more_rounded));

    expect(
      decoration.color,
      colors.surfaceContainerHighest.withValues(alpha: 0.5),
    );
    expect(border.top.color, colors.outlineVariant.withValues(alpha: 0.32));
    expect(icon.color, colors.onSurfaceVariant.withValues(alpha: 0.55));
    expect(rotation.turns, 0);
  });
}
