import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/domain/calorie_age_calculator.dart';
import 'package:yamt/features/onboarding/presentation/'
    'calorie_goal_onboarding_keys.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_field_card.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_wheel.dart';
import 'package:yamt/features/onboarding/presentation/widgets/intro/fields/'
    'intro_wheel_selection_band.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Youngest age the calorie calculator accepts.
const _minimumAgeYears = 16;

/// Oldest age the birthday wheels offer.
const _maximumAgeYears = 100;

/// Age the wheels start on while no birthday is picked.
const _defaultAgeYears = 30;

/// Months in a year.
const _monthsPerYear = 12;

/// Card that collects a birthday through day, month, and year wheels.
class IntroBirthDateCard extends StatelessWidget {
  /// Creates the birthday card.
  const new({
    required this.birthDate,
    required this.today,
    required this.errorText,
    required this.onChanged,
    this.expand = false,
    super.key,
  });

  /// Picked birthday, or `null` while the user has not touched a wheel.
  final DateTime? birthDate;

  /// Current day, used for the selectable year range.
  final DateTime today;

  /// Validation error text.
  final String? errorText;

  /// Called with the complete birthday whenever a wheel settles.
  final ValueChanged<DateTime> onChanged;

  /// Whether the wheels fill the height the parent gives the card.
  final bool expand;

  DateTime get _shownDate =>
      birthDate ??
      DateTime(today.year - _defaultAgeYears, today.month, today.day);

  DateTime get _firstDate =>
      DateTime(today.year - _maximumAgeYears, today.month, today.day);

  DateTime get _lastDate =>
      DateTime(today.year - _minimumAgeYears, today.month, today.day);

  void _emit({int? day, int? month, int? year}) {
    final shown = _shownDate;
    final nextYear = year ?? shown.year;
    final nextMonth = month ?? shown.month;
    final nextDay = (day ?? shown.day).clamp(
      1,
      _daysInMonth(nextYear, nextMonth),
    );

    final candidate = DateTime(nextYear, nextMonth, nextDay);
    if (candidate.isBefore(_firstDate)) {
      onChanged(_firstDate);
      return;
    }
    if (candidate.isAfter(_lastDate)) {
      onChanged(_lastDate);
      return;
    }
    onChanged(candidate);
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _valueText(BuildContext context, AppLocalizations l10n) {
    final date = birthDate;
    if (date == null) {
      return introFieldEmptyValue;
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return l10n.introBirthDateValue(
      DateFormat.yMd(locale).format(date),
      ageInYearsAt(date, today).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthFormat = DateFormat.MMM(locale);
    final shown = _shownDate;
    final firstYear = _firstDate.year;

    return IntroFieldCard(
      icon: Icons.cake_outlined,
      label: l10n.introBirthDateLabel,
      valueText: _valueText(context, l10n),
      errorText: errorText,
      expand: expand,
      child: Column(
        children: [
          Row(
            children: [
              _WheelLabel(text: l10n.introBirthDayLabel),
              _WheelLabel(text: l10n.introBirthMonthLabel),
              _WheelLabel(text: l10n.introBirthYearLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _MaybeExpanded(
            expand: expand,
            child: IntroWheelSelectionBand(
              child: Row(
                children: [
                  Expanded(
                    child: IntroWheel(
                      key: CalorieGoalOnboardingKeys.introBirthDayWheel,
                      itemCount: _daysInMonth(shown.year, shown.month),
                      selectedIndex: shown.day - 1,
                      labelBuilder: (index) => '${index + 1}',
                      onSelected: (index) => _emit(day: index + 1),
                    ),
                  ),
                  Expanded(
                    child: IntroWheel(
                      key: CalorieGoalOnboardingKeys.introBirthMonthWheel,
                      itemCount: _monthsPerYear,
                      selectedIndex: shown.month - 1,
                      labelBuilder: (index) =>
                          monthFormat.format(DateTime(shown.year, index + 1)),
                      onSelected: (index) => _emit(month: index + 1),
                    ),
                  ),
                  Expanded(
                    child: IntroWheel(
                      key: CalorieGoalOnboardingKeys.introBirthYearWheel,
                      itemCount: _lastDate.year - firstYear + 1,
                      selectedIndex: shown.year - firstYear,
                      labelBuilder: (index) => '${firstYear + index}',
                      onSelected: (index) => _emit(year: firstYear + index),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps [child] in [Expanded] when the card fills its parent.
class _MaybeExpanded extends StatelessWidget {
  const new({required this.expand, required this.child});

  final bool expand;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return expand ? Expanded(child: child) : child;
  }
}

class _WheelLabel extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
