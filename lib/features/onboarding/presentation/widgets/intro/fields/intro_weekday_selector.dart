import 'package:intl/intl.dart' as intl;
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_intro_layout_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Renders a row of selectable weekday chips (Monday-Sunday).
class IntroWeekdaySelector extends StatelessWidget {
  /// Creates a weekday selector row.
  const new({
    required this.selectedWeekdays,
    required this.onToggleWeekday,
    super.key,
  });

  /// The currently selected weekday indices (1 = Monday .. 7 = Sunday).
  final List<int> selectedWeekdays;

  /// Callback when a weekday chip is toggled.
  final ValueChanged<int> onToggleWeekday;

  static String _weekdayLabel(BuildContext context, int weekday) {
    final date = DateTime(2026, 1, 4 + weekday);
    final locale = Localizations.localeOf(context).toString();
    final full = intl.DateFormat.E(locale).format(date);
    return full.length <= 2 ? full : full.substring(0, 2);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final weekday = index + 1;
        final isSelected = selectedWeekdays.contains(weekday);

        return _WeekdayChip(
          label: _weekdayLabel(context, weekday),
          isSelected: isSelected,
          onTap: () => onToggleWeekday(weekday),
        );
      }),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const new({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppInkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: AppIntroLayout.weekdayChip,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary
              : colors.surfaceContainerHighest.withValues(
                  alpha: AppIntroLayout.weekdayIdleOpacity,
                ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? colors.onPrimary : colors.onSurface,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
