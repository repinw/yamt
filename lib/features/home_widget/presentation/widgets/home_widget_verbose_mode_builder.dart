import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/home_widget/presentation/controllers/'
    'home_widget_verbose_mode_controller.dart';

/// Builds a control for the home-screen widget's silent/verbose choice.
///
/// Public edge for surfaces owned by other features (the Settings row):
/// they get the current value and a toggle without reaching into the
/// controller.
class HomeWidgetVerboseModeBuilder extends ConsumerWidget {
  /// Creates the verbose-mode builder.
  const new({required this.builder, super.key});

  /// Builds the control from whether verbose mode is on and a toggle.
  final Widget Function(
    BuildContext context, {
    required bool verbose,
    required VoidCallback toggle,
  })
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return builder(
      context,
      verbose: ref.watch(homeWidgetVerboseModeControllerProvider),
      toggle: () => unawaited(
        ref.read(homeWidgetVerboseModeControllerProvider.notifier).toggle(),
      ),
    );
  }
}
