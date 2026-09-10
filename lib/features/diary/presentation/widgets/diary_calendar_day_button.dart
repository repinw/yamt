import 'package:flutter/material.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';

/// Single day button used by the diary calendar strip.
class DiaryCalendarDayButton extends StatelessWidget {
  /// The diary calendar day button.
  const DiaryCalendarDayButton({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.activeColor,
    required this.inactiveTextColor,
    required this.onTap,
    super.key,
  });

  /// The represented day.
  final DateTime day;

  /// Whether this day is selected.
  final bool isActive;

  /// Whether this day is today.
  final bool isToday;

  /// The active day color.
  final Color activeColor;

  /// The inactive text color.
  final Color inactiveTextColor;

  /// Called when tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeTextColor =
        ThemeData.estimateBrightnessForColor(activeColor) == Brightness.dark
            ? Colors.white
            : const Color(0xFF0F172A);
    final textColor = isActive ? activeTextColor : inactiveTextColor;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: AppInkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      calendarWeekdayLabel(day, localeName).toUpperCase(),
                      style: TextStyle(
                        color: isActive
                            ? activeTextColor.withValues(alpha: 0.9)
                            : inactiveTextColor,
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: isActive
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (isToday && !isActive)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
