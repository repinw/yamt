import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';

class CaloriesDayNavigationCard extends StatelessWidget {
  const CaloriesDayNavigationCard({
    super.key,
    required this.dayLabel,
    required this.onPreviousDay,
    required this.onToday,
    required this.onNextDay,
    required this.previousDayTooltip,
    required this.todayLabel,
    required this.nextDayTooltip,
  });

  final String dayLabel;
  final VoidCallback onPreviousDay;
  final VoidCallback onToday;
  final VoidCallback onNextDay;
  final String previousDayTooltip;
  final String todayLabel;
  final String nextDayTooltip;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppInsets.card,
        child: Row(
          children: <Widget>[
            IconButton(
              key: CaloriesPageKeys.dayBackButton,
              tooltip: previousDayTooltip,
              onPressed: onPreviousDay,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                dayLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              key: CaloriesPageKeys.dayTodayButton,
              onPressed: onToday,
              child: Text(todayLabel),
            ),
            IconButton(
              key: CaloriesPageKeys.dayForwardButton,
              tooltip: nextDayTooltip,
              onPressed: onNextDay,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
