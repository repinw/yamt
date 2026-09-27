import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';

/// A titled group of entries in the home side menu.
class HomeMenuSection extends StatelessWidget {
  /// Creates a menu section.
  const new({required this.title, required this.entries, super.key});

  /// Small caption above the entries.
  final String title;

  /// The entries of the group.
  final List<Widget> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: AppFoodLabel.brandTracking,
              ),
            ),
          ),
          ...entries,
        ],
      ),
    );
  }
}
