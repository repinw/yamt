import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Für Mi · Frühstück": the planned meal [plan] stands for. A day in the
/// coming week shows as its weekday; one that has passed, or lies further
/// ahead, as its date, so the text never names the wrong week. [now] is the
/// time of the app clock.
String shoppingPlannedForText(
  BuildContext context,
  ShoppingPlannedMeal plan, {
  required DateTime now,
}) {
  final l10n = AppLocalizations.of(context)!;
  final localeName = Localizations.localeOf(context).toLanguageTag();
  final today = normalizeLocalDay(now);
  final day = normalizeLocalDay(plan.day);
  final inComingWeek =
      !day.isBefore(today) &&
      day.isBefore(DateTime(today.year, today.month, today.day + 7));
  return l10n.shoppingListPlannedFor(
    (inComingWeek ? DateFormat.E(localeName) : DateFormat.MMMd(localeName))
        .format(day),
    plan.mealType.localizedName(l10n),
  );
}

/// The note of [item] and the meal it is planned for, joined: "500 g · Für
/// Mi · Frühstück". Empty when the entry has neither.
String shoppingEntryNoteText(
  BuildContext context,
  ShoppingListItem item, {
  required DateTime now,
}) {
  final plan = item.plannedFor;
  return [
    ?item.note,
    if (plan != null) shoppingPlannedForText(context, plan, now: now),
  ].join(AppLocalizations.of(context)!.shoppingDetailSeparator);
}
