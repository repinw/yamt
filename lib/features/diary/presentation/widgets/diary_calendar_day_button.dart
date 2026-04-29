import 'package:flutter/material.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_date_utils.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isActive ? Colors.white : inactiveTextColor;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 64,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      diaryWeekdayLabel(day, localeName).toUpperCase(),
                      style: TextStyle(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.9)
                            : inactiveTextColor,
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
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
                        color: isDark ? const Color(0xFF34D399) : activeColor,
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
