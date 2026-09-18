import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Stacks picker cards so they split the available height evenly.
///
/// With `fill` false the cards keep their natural height, for pages that
/// scroll.
class IntroPickerStack extends StatelessWidget {
  /// Creates a picker stack.
  const new({required this.fill, required this.children, super.key});

  /// Whether the cards share the height the parent gives the stack.
  final bool fill;

  /// Picker cards, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          if (fill) Expanded(child: children[index]) else children[index],
        ],
      ],
    );
  }
}
