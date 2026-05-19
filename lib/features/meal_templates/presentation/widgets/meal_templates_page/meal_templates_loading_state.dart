import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Loading state for the cookbook page.
class MealTemplatesLoadingState extends StatelessWidget {
  /// Creates the loading state widget.
  const MealTemplatesLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: AppSizes.inlineProgressIndicator,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.progressStrokeWidth,
        ),
      ),
    );
  }
}
