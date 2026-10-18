import 'package:meta/meta.dart';

/// What the user chose in the sheet of a weighing.
@immutable
sealed class ProgressWeighingAction {
  const new();
}

/// Store the weighing as [weightKg] at [at].
final class ProgressWeighingSave extends ProgressWeighingAction {
  /// Creates the action.
  const new({required this.at, required this.weightKg});

  /// When the user weighed.
  final DateTime at;

  /// The weight.
  final double weightKg;
}

/// Delete the weighing.
final class ProgressWeighingDelete extends ProgressWeighingAction {
  /// Creates the action.
  const new();
}

/// Leave the weighing out of every count, or count it again.
final class ProgressWeighingIgnore extends ProgressWeighingAction {
  /// Creates the action.
  const new({required this.ignored});

  /// Whether the weighing no longer counts.
  final bool ignored;
}

/// Open the Health app, where weighings of other apps are deleted.
final class ProgressWeighingOpenHealth extends ProgressWeighingAction {
  /// Creates the action.
  const new();
}
