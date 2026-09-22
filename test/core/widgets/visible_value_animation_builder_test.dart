import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/content_visibility.dart';
import 'package:yamt/core/widgets/value_animation_handoff.dart';
import 'package:yamt/core/widgets/visible_value_animation_builder.dart';

void main() {
  const duration = Duration(milliseconds: 1000);

  Widget animated(ValueListenable<double> value, List<double> shown) {
    return ValueListenableBuilder<double>(
      valueListenable: value,
      builder: (context, target, _) => VisibleValueAnimationBuilder(
        value: target,
        duration: duration,
        curve: Curves.linear,
        builder: (context, animatedValue, _) {
          shown.add(animatedValue);
          return const SizedBox();
        },
      ),
    );
  }

  testWidgets('animates from zero and between values', (tester) async {
    final value = ValueNotifier<double>(10);
    addTearDown(value.dispose);
    final shown = <double>[];
    await tester.pumpWidget(MaterialApp(home: animated(value, shown)));

    expect(shown.last, 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown.last, closeTo(5, 0.01));
    await tester.pumpAndSettle();
    expect(shown.last, 10);

    value.value = 4;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown.last, closeTo(7, 0.01));
    await tester.pumpAndSettle();
    expect(shown.last, 4);
  });

  testWidgets('a change behind another route plays after returning', (
    tester,
  ) async {
    final value = ValueNotifier<double>(10);
    addTearDown(value.dispose);
    final shown = <double>[];
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigatorKey, home: animated(value, shown)),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    value.value = 2;
    await tester.pump(const Duration(seconds: 3));

    navigatorKey.currentState!.pop();
    await tester.pump();
    expect(shown.last, 10);

    await tester.pumpAndSettle();
    expect(shown, contains(closeTo(6, 1)));
    expect(shown.last, 2);
  });

  testWidgets('a change on a hidden tab plays once the tab shows', (
    tester,
  ) async {
    final value = ValueNotifier<double>(10);
    addTearDown(value.dispose);
    final shown = <double>[];
    final enabled = ValueNotifier<bool>(true);
    addTearDown(enabled.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, isEnabled, child) =>
              TickerMode(enabled: isEnabled, child: child!),
          child: animated(value, shown),
        ),
      ),
    );
    await tester.pumpAndSettle();

    enabled.value = false;
    await tester.pump();
    value.value = 20;
    await tester.pump(const Duration(seconds: 3));
    expect(shown.last, 10);

    enabled.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown.last, closeTo(15, 0.01));
    await tester.pumpAndSettle();
    expect(shown.last, 20);
  });

  testWidgets('a change while the content is covered plays once visible', (
    tester,
  ) async {
    final value = ValueNotifier<double>(10);
    addTearDown(value.dispose);
    final shown = <double>[];
    final visible = ValueNotifier<bool>(true);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: visible,
          builder: (context, isVisible, child) =>
              ContentVisibility(isVisible: isVisible, child: child!),
          child: animated(value, shown),
        ),
      ),
    );
    await tester.pumpAndSettle();

    visible.value = false;
    value.value = 0;
    await tester.pump(const Duration(seconds: 3));
    expect(shown.last, 10);

    visible.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(shown.last, closeTo(5, 0.01));
    await tester.pumpAndSettle();
    expect(shown.last, 0);
  });

  testWidgets('the next visible builder continues from the handed value', (
    tester,
  ) async {
    final firstVisible = ValueNotifier<bool>(true);
    addTearDown(firstVisible.dispose);
    final first = <double>[];
    final second = <double>[];
    Widget tagged(double value, List<double> shown) =>
        VisibleValueAnimationBuilder(
          value: value,
          duration: duration,
          curve: Curves.linear,
          handoffTag: #bar,
          builder: (context, animatedValue, _) {
            shown.add(animatedValue);
            return const SizedBox();
          },
        );
    await tester.pumpWidget(
      MaterialApp(
        home: ValueAnimationHandoffScope(
          handoff: ValueAnimationHandoff(),
          child: ValueListenableBuilder<bool>(
            valueListenable: firstVisible,
            builder: (context, isFirst, _) => Column(
              children: [
                ContentVisibility(isVisible: isFirst, child: tagged(10, first)),
                ContentVisibility(
                  isVisible: !isFirst,
                  child: tagged(30, second),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(first.last, 10);
    // The hidden builder waits at the value the visible one shows.
    expect(second.last, 10);

    firstVisible.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(second.last, closeTo(20, 0.01));
    await tester.pumpAndSettle();
    expect(second.last, 30);
    expect(first.last, 30);
  });
}
