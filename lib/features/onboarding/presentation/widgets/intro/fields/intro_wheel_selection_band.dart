import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Highlight band that marks the selected row of one or more `IntroWheel`s.
class IntroWheelSelectionBand extends StatelessWidget {
  /// Creates a selection band around [child].
  const new({required this.child, super.key});

  /// The wheels the band sits behind.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: AppIntroLayout.wheelItemExtent,
          decoration: BoxDecoration(
            color: colors.primary.withValues(
              alpha: AppIntroLayout.wheelSelectionOpacity,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child,
      ],
    );
  }
}
