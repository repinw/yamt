import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// Placeholder shown while the diary meals load.
class DiaryMealsSkeleton extends StatelessWidget {
  /// Creates the meals loading skeleton.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}
