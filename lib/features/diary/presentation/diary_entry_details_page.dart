import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_entry_details_state.dart';
import 'package:yamt/features/diary/presentation/diary_entry_delete_flow.dart';
import 'package:yamt/features/diary/presentation/diary_entry_details_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_entry_label_section.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_components_list.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Details of a logged diary entry, in the food label look of the eat page.
///
/// The label shows the nutrients of the eaten amount. The main button logs
/// the food again ("Nochmal"); once the amount on the ruler changed, it
/// saves that amount instead ("Speichern") and closes the page. Icons beside
/// it remove the entry and plan the food again for a later day. Moving the
/// entry to another meal or day saves at once. Every change offers an undo,
/// and an entry logged from the inventory moves or returns its stock with it.
class DiaryEntryDetailsPage extends ConsumerStatefulWidget {
  /// Creates the page for the entry with [entryId].
  const new({required this.entryId, super.key});

  /// Key of the main button: "Nochmal", or "Speichern" for a changed amount.
  static const saveButtonKey = Key('diary_entry_details_save_button');

  /// Key of the close button.
  static const closeButtonKey = Key('diary_entry_details_close_button');

  /// Id of the logged entry.
  final String entryId;

  @override
  ConsumerState<DiaryEntryDetailsPage> createState() =>
      _DiaryEntryDetailsPageState();
}

class _DiaryEntryDetailsPageState extends ConsumerState<DiaryEntryDetailsPage> {
  late final DiaryEntryDetailsControllerProvider _provider =
      diaryEntryDetailsControllerProvider(widget.entryId);
  final _amount = EatSheetTextField();
  var _isSaving = false;

  DiaryEntryDetailsController get _controller => ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    _syncAmount(ref.read(_provider).value);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(_provider, (_, next) => _syncAmount(next.value));
    return ref
        .watch(_provider)
        .when(
          data: (state) => state == null
              ? _StatusScaffold(message: l10n.caloriesEntryNotFound)
              : PopScope<void>(canPop: !_isSaving, child: _content(state)),
          loading: () => const _StatusScaffold(),
          error: (_, _) => _StatusScaffold(message: l10n.caloriesLoadFailed),
        );
  }

  Widget _content(DiaryEntryDetailsState state) {
    final l10n = AppLocalizations.of(context)!;
    final entry = state.entry;
    // An invalid amount counts as changed, so nothing repeats the stored one.
    final isChanged = state.changedAmount != null || state.hasAmountError;
    final canRepeat = canRepeatCalorieEntry(entry);
    return EatPageScaffold(
      // The snack bars of the changes use the app's messenger, so they
      // stay on the diary after the page closes.
      whenControl: EatWhenMenu(
        loggedAt: entry.loggedAt,
        today: state.today,
        mealType: entry.mealType,
        onMealTypeChanged: (type) =>
            unawaited(_move(() => _controller.moveToMeal(type))),
        onDayPicked: (day) =>
            unawaited(_move(() => _controller.moveToDay(day))),
      ),
      kcal: state.preview.totalKcal,
      // A prepared meal's portions cannot repeat; its button only closes.
      confirmLabel: isChanged || !canRepeat
          ? l10n.caloriesSaveEntryAction
          : l10n.diaryEntryAgainAction,
      confirmButtonKey: DiaryEntryDetailsPage.saveButtonKey,
      onConfirm: _isSaving || state.hasAmountError
          ? null
          : () => unawaited(
              isChanged || !canRepeat ? _save(state) : _eatAgain(entry),
            ),
      // The icons stay while a change saves; _run ignores a second tap.
      onDelete: () => unawaited(
        _run(() => DiaryEntryDeleteFlow.remove(context, entry: entry)),
      ),
      onPlan: isChanged || !canRepeat
          ? null
          : () => unawaited(_planAgain(state)),
      cancelButtonKey: DiaryEntryDetailsPage.closeButtonKey,
      children: [
        DiaryEntryLabelSection(entry: state.preview),
        if (state.canEditAmount)
          EatAmountRuler(
            controller: _amount.controller,
            focusNode: _amount.focusNode,
            unitLabel: consumedUnitSymbol(l10n, entry.consumedUnit),
            value: state.rulerValue,
            max: state.rulerMax,
            step: state.rulerStep,
            marks: const [],
            allowFractionalInput: true,
            errorText: state.hasAmountError
                ? l10n.caloriesPositiveNumberValidation
                : null,
            onTextChanged: (text) => _controller.setAmountText(text),
            onSliderChanged: (amount) => _controller.pickAmount(amount),
          ),
        if (entry.isBundle)
          EatComponentsList(
            initiallyExpanded: true,
            components: [
              for (final food in entry.bundleComponents)
                (
                  name: food.name,
                  amount: food.amountLabel,
                  kcal: food.totalKcal,
                ),
            ],
          ),
      ],
    );
  }

  void _syncAmount(DiaryEntryDetailsState? state) {
    if (state != null) {
      _amount.sync(state.amountText);
    }
  }

  /// Saves the move that [start] shows, and shows the stored entry again
  /// when the save fails.
  Future<void> _move(DiaryEntryMove? Function() start) {
    return _run(() async {
      final move = start();
      if (move == null) {
        return;
      }
      final saved = await DiaryEntryDetailsFlow.saveChange(
        context,
        previous: move.previous,
        updated: move.updated,
        onUndone: _reloadAfterUndo(),
      );
      if (!saved && mounted) {
        _controller.showEntry(move.previous);
      }
    });
  }

  /// Saves the changed amount and closes the page. Without a changed
  /// amount the page only closes.
  Future<void> _save(DiaryEntryDetailsState state) {
    return _run(() async {
      final amount = state.changedAmount;
      if (amount == null) {
        context.pop();
        return;
      }
      final saved = await DiaryEntryDetailsFlow.changeAmount(
        context,
        entry: state.entry,
        amount: amount,
        onUndone: _reloadAfterUndo(),
      );
      if (saved && mounted) {
        context.pop();
      }
    });
  }

  Future<void> _eatAgain(CalorieEntry entry) =>
      _run(() => DiaryEntryDetailsFlow.eatAgain(context, entry: entry));

  /// Asks for the day, then plans the food again for it.
  Future<void> _planAgain(DiaryEntryDetailsState state) => _run(() async {
    final day = await showEatPlanDayPicker(
      context,
      today: state.today,
      loggedAt: addDiaryDays(state.today, 1),
    );
    if (day != null && mounted) {
      await DiaryEntryDetailsFlow.planAgain(
        context,
        entry: state.entry,
        day: day,
      );
    }
  });

  /// Reloads the entry after an undo. The undo may run after the page
  /// closed, so it uses the container instead of this state's `ref`.
  VoidCallback _reloadAfterUndo() {
    final container = ProviderScope.containerOf(context, listen: false);
    final provider = _provider;
    return () => container.invalidate(provider);
  }

  /// Runs [action] unless another one runs. The page's buttons are muted
  /// and the page stays open meanwhile.
  Future<void> _run(Future<void> Function() action) async {
    if (_isSaving) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isSaving = true);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Page shown while the entry loads, or with [message] when it cannot show
/// the entry.
class _StatusScaffold extends StatelessWidget {
  const new({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    return Scaffold(
      backgroundColor: FoodLabelColors.of(context).paper,
      appBar: message == null
          ? null
          : AppBar(
              title: Text(
                AppLocalizations.of(context)!.caloriesEntryDetailsTitle,
              ),
            ),
      body: Center(
        child: message == null
            ? const SizedBox.square(
                dimension: AppSizes.inlineProgressIndicator,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.progressStrokeWidth,
                ),
              )
            : Text(message),
      ),
    );
  }
}
