import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_background.dart';

void main() {
  testWidgets('paints the editorial app background surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(seedColor: AppColors.seed),
        home: const AppBackground(
          child: SizedBox(key: ValueKey<String>('background-child')),
        ),
      ),
    );

    final context = tester.element(find.byType(AppBackground));
    final colors = Theme.of(context).colorScheme;
    final background = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = background.decoration as BoxDecoration;

    expect(decoration.color, AppEditorialSurfaces.appBackground(colors));
    expect(
      find.byKey(const ValueKey<String>('background-child')),
      findsOneWidget,
    );
  });
}
