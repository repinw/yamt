import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Shared horizontal quick chip scroller.
class InventoryEatFlowQuickChipScroller extends StatelessWidget {
  /// Creates quick chip scroller.
  const InventoryEatFlowQuickChipScroller({
    required this.children,
    super.key,
  });

  /// Children.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}
