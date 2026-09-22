import 'package:material_ui/material_ui.dart';

/// Last values shown by tagged `VisibleValueAnimationBuilder`s below one
/// [ValueAnimationHandoffScope].
///
/// A builder that becomes visible starts from the value its tag showed last,
/// so a bar on the next page continues from the same bar on the page before.
/// Hidden builders follow the value while they wait.
class ValueAnimationHandoff {
  final Map<Object, ValueNotifier<double?>> _values =
      <Object, ValueNotifier<double?>>{};

  /// Value last shown under [tag], or null if none was shown yet.
  double? valueOf(Object tag) => _values[tag]?.value;

  /// Remembers [value] as shown under [tag].
  void record(Object tag, double value) => _slot(tag).value = value;

  /// Calls [listener] whenever the value under [tag] changes.
  void addListener(Object tag, VoidCallback listener) =>
      _slot(tag).addListener(listener);

  /// Stops calling [listener] for [tag].
  void removeListener(Object tag, VoidCallback listener) =>
      _values[tag]?.removeListener(listener);

  /// Releases the listeners.
  void dispose() {
    for (final value in _values.values) {
      value.dispose();
    }
  }

  ValueNotifier<double?> _slot(Object tag) =>
      _values.putIfAbsent(tag, () => ValueNotifier<double?>(null));
}

/// Shares one [ValueAnimationHandoff] with the builders below.
class ValueAnimationHandoffScope extends InheritedWidget {
  /// Creates the scope.
  const new({required this.handoff, required super.child, super.key});

  /// Values handed from one builder to the next.
  final ValueAnimationHandoff handoff;

  /// Handoff of the nearest scope, or null outside of one.
  static ValueAnimationHandoff? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<ValueAnimationHandoffScope>()
      ?.handoff;

  @override
  bool updateShouldNotify(ValueAnimationHandoffScope oldWidget) =>
      handoff != oldWidget.handoff;
}
