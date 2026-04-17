import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';

void main() {
  testWidgets('caps aggressive text scaling', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AppResponsiveViewport(child: _TextScaleProbe()),
        ),
      ),
    );

    expect(find.text('12.0'), findsOneWidget);
  });

  testWidgets('uses compact visual density on tight widths', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 640)),
        child: Theme(
          data: ThemeData(useMaterial3: true),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: AppResponsiveViewport(child: _VisualDensityProbe()),
          ),
        ),
      ),
    );

    expect(find.text('compact'), findsOneWidget);
  });
}

class _TextScaleProbe extends StatelessWidget {
  const _TextScaleProbe();

  @override
  Widget build(BuildContext context) {
    final scaledFontSize = MediaQuery.textScalerOf(context).scale(10);
    return Text(scaledFontSize.toStringAsFixed(1));
  }
}

class _VisualDensityProbe extends StatelessWidget {
  const _VisualDensityProbe();

  @override
  Widget build(BuildContext context) {
    final density = Theme.of(context).visualDensity;
    final isCompact = density == VisualDensity.compact;
    return Text(isCompact ? 'compact' : 'regular');
  }
}
