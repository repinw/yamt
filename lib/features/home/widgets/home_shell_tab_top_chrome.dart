import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_debug_actions_menu.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/diary/provider/diary_calendar_controller.dart';
import 'package:yamt/features/home/widgets/home_heart_counter_button.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart';
import 'package:yamt/features/inventory/provider/'
    'prepared_meal_selection_controller.dart';
import 'package:yamt/features/kitchen_utensils/presentation/widgets/'
    'kitchen_utensils_button.dart';
import 'package:yamt/features/meal_templates/presentation/widgets/'
    'meal_template_recipe_import_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shared top chrome rendered inside each home tab scroll view.
class HomeShellTabTopChrome extends ConsumerWidget {
  /// The home tab top chrome.
  const HomeShellTabTopChrome({required this.tab, super.key});

  /// The tab currently rendering this top chrome.
  final HomeTabType tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final colors = Theme.of(context).colorScheme;
    final compact = shouldUseCompactHomeChrome(context);
    final selectionState = ref.watch(preparedMealSelectionControllerProvider);
    final diaryCalendarState = tab == HomeTabType.diary
        ? ref.watch(diaryCalendarControllerProvider)
        : null;
    final runState = ref.watch(burnWeekRunControllerProvider).asData?.value;
    final subtitle = _subtitleForTab(diaryCalendarState, localeName);

    return HomeShellTopSliverChrome(
      child: HomeTopBar(
        title: _titleForTab(
          l10n,
          selectionState,
          diaryCalendarState,
          localeName,
        ),
        subtitle: subtitle,
        middle: _buildMiddle(tab, runState),
        titleColor: colors.primary,
        compact: compact,
        preferredHeight: HomeTopBar.preferredHeightFor(
          context,
          compact: compact,
          hasSubtitle: subtitle != null,
        ),
        actions: _buildActions(
          context,
          ref,
          l10n,
          selectionState,
          compact,
          diaryCalendarState,
        ),
      ),
    );
  }

  String _titleForTab(
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    DiaryCalendarState? diaryCalendarState,
    String localeName,
  ) {
    if (tab == HomeTabType.inventory && selectionState.isSelectionMode) {
      return l10n.preparedMealSelectionCount(selectionState.selectedCount);
    }

    return switch (tab) {
      HomeTabType.inventory => l10n.inventoryPageTitle,
      HomeTabType.diary =>
        diaryCalendarState?.isSelectedToday ?? true
            ? l10n.diaryTodayTitle
            : calendarWeekdayFullLabel(
                diaryCalendarState!.selectedDay,
                localeName,
              ),
      HomeTabType.cookbook => l10n.homeCookbook,
      HomeTabType.statistics => l10n.homeStatistics,
      HomeTabType.settings => l10n.homeSettings,
    };
  }

  String? _subtitleForTab(
    DiaryCalendarState? diaryCalendarState,
    String localeName,
  ) {
    if (diaryCalendarState == null) {
      return null;
    }

    return formatCalendarHeaderDate(diaryCalendarState.selectedDay, localeName);
  }

  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    bool useCompactSelectionActions,
    DiaryCalendarState? diaryCalendarState,
  ) {
    if (tab == HomeTabType.inventory && selectionState.isSelectionMode) {
      return _buildInventorySelectionActions(
        ref,
        l10n,
        selectionState,
        useCompactSelectionActions,
      );
    }

    return switch (tab) {
      HomeTabType.inventory => [
        IconButton(
          tooltip: l10n.commonNotImplementedYet,
          onPressed: () => _showSnackBar(context, l10n.commonNotImplementedYet),
          icon: const Icon(Icons.assignment_outlined),
        ),
        IconButton(
          tooltip: l10n.homeShopping,
          onPressed: () => context.push(AppRoutes.homeShopping),
          icon: const Icon(Icons.shopping_cart_rounded),
        ),
      ],
      HomeTabType.diary => _buildDiaryActions(
        ref,
        l10n,
        diaryCalendarState,
      ),
      HomeTabType.cookbook => const [
        KitchenUtensilsButton(),
        MealTemplateRecipeImportButton(),
      ],
      HomeTabType.statistics || HomeTabType.settings => const <Widget>[],
    };
  }

  List<Widget> _buildInventorySelectionActions(
    WidgetRef ref,
    AppLocalizations l10n,
    PreparedMealSelectionState selectionState,
    bool useCompactSelectionActions,
  ) {
    final isAddingIngredients = selectionState.isAddingIngredientsToMeal;
    final selectionActionLabel = isAddingIngredients
        ? l10n.preparedMealAddIngredientAction
        : l10n.preparedMealBindAction;
    final selectionActionIcon = isAddingIngredients
        ? Icons.add_rounded
        : Icons.restaurant_menu_rounded;
    final canConfirmSelection =
        selectionState.selectedCount >= (isAddingIngredients ? 1 : 2);

    if (useCompactSelectionActions) {
      return [
        IconButton(
          tooltip: l10n.inventoryReceiptReviewCancelAction,
          onPressed: () {
            ref
                .read(preparedMealSelectionControllerProvider.notifier)
                .clearSelection();
          },
          icon: const Icon(Icons.close_rounded),
        ),
        IconButton.filledTonal(
          tooltip: selectionActionLabel,
          onPressed: canConfirmSelection
              ? () {
                  ref
                      .read(preparedMealSelectionControllerProvider.notifier)
                      .confirmSelection();
                }
              : null,
          icon: Icon(selectionActionIcon),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: () {
          ref
              .read(preparedMealSelectionControllerProvider.notifier)
              .clearSelection();
        },
        child: Text(l10n.inventoryReceiptReviewCancelAction),
      ),
      FilledButton.tonalIcon(
        onPressed: canConfirmSelection
            ? () {
                ref
                    .read(preparedMealSelectionControllerProvider.notifier)
                    .confirmSelection();
              }
            : null,
        icon: Icon(selectionActionIcon),
        label: Text(selectionActionLabel),
      ),
    ];
  }

  List<Widget> _buildDiaryActions(
    WidgetRef ref,
    AppLocalizations l10n,
    DiaryCalendarState? diaryCalendarState,
  ) {
    return [
      if (kDebugMode) const CalorieDebugActionsMenu(),
      if (diaryCalendarState != null && !diaryCalendarState.isSelectedToday)
        TextButton(
          onPressed: () {
            ref.read(diaryCalendarControllerProvider.notifier).selectToday();
          },
          child: Text(l10n.diaryTodayTitle),
        ),
    ];
  }

  Widget? _buildMiddle(HomeTabType currentTab, BurnWeekRunState? runState) {
    if (currentTab != HomeTabType.diary) {
      return null;
    }
    if (runState == null ||
        runState.runWeekNumber <= burnWeekLearningRunWeekNumber) {
      return null;
    }
    return HomeHeartCounterButton(runState: runState);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
