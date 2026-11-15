import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';

/// Framed row of something still on its way into the Vorrat: a tilted
/// picture, a name, a status, an optional [detail] line, and one button.
class CookbookRunningCard extends StatelessWidget {
  /// Creates the row.
  const new({
    required this.picture,
    required this.name,
    required this.status,
    required this.action,
    required this.onAction,
    required this.attention,
    this.detail,
    this.actionKey,
    super.key,
  });

  /// Words [time]: its time of day when it is on the day of [now], else its
  /// day, since a pot can stay open for days.
  static String timeOrDay(BuildContext context, DateTime time, DateTime now) {
    final localizations = MaterialLocalizations.of(context);
    final local = time.toLocal();
    return DateUtils.isSameDay(local, now)
        ? localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))
        : localizations.formatShortMonthDay(local);
  }

  /// The picture, already sized.
  final Widget picture;

  /// The meal's name.
  final String name;

  /// Where it stands.
  final String status;

  /// Who and since when, under the status.
  final String? detail;

  /// Whether [status] asks for the cook's attention.
  final bool attention;

  /// The button's label.
  final String action;

  /// Called by the button.
  final VoidCallback onAction;

  /// Key of the button.
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final detail = this.detail;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.ink, width: AppFoodLabel.chipOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            Transform.rotate(angle: AppFoodLabel.imageTilt, child: picture),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xxs,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: attention ? colors.low : colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.muted,
                      ),
                    ),
                ],
              ),
            ),
            FilledButton.tonal(
              key: actionKey,
              onPressed: onAction,
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }
}
