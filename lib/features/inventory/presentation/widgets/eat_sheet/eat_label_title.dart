import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Title of a food label box, with the heavy rule under it.
class EatLabelTitle extends StatelessWidget {
  /// Creates the title.
  const new({required this.text, this.trailing = const <Widget>[], super.key});

  /// Title text.
  final String text;

  /// Widgets at the end of the title line, such as column headers.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.ink,
            width: AppFoodLabel.labelHeaderRule,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                  height: 1,
                ),
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
  }
}
