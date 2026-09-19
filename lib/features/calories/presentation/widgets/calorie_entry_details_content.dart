import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_entry_edits.dart';
import 'package:yamt/features/calories/presentation/controllers/'
    'calorie_entry_editor_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_actions.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_amount_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_view.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_dialogs.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_editor_flow_handler.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Details sheet content for a logged entry.
///
/// Meal, time, and amount changes save at once and offer an undo. The sheet
/// shows the changed entry right away and switches back to the stored entry
/// once the provider delivers it.
class CalorieEntryDetailsContent extends ConsumerStatefulWidget {
  /// Creates the details content.
  const new({required this.entryId, super.key});

  /// Id of the logged entry.
  final String entryId;

  @override
  ConsumerState<CalorieEntryDetailsContent> createState() =>
      _CalorieEntryDetailsContentState();
}

class _CalorieEntryDetailsContentState
    extends ConsumerState<CalorieEntryDetailsContent> {
  /// Entry shown while a change is saving.
  CalorieEntry? _pending;

  CalorieEntryEditorController get _controller =>
      ref.read(calorieEntryEditorControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = calorieEntryByIdProvider(widget.entryId);
    ref.listen(provider, (previous, next) {
      if (_pending != null && next.hasValue && !next.isLoading) {
        setState(() => _pending = null);
      }
    });
    final isSaving = ref.watch(calorieEntryEditorControllerProvider);

    return ref
        .watch(provider)
        .when(
          data: (loaded) {
            if (loaded == null) {
              return _MessageScaffold(message: l10n.caloriesEntryNotFound);
            }
            final entry = _pending ?? loaded;
            return PopScope<void>(
              canPop: !isSaving,
              child: CalorieEntryDetailsView(
                entry: entry,
                isSaving: isSaving,
                canEatAgain: canRepeatCalorieEntry(entry),
                onClose: _close,
                onMealTypeChanged: (mealType) => unawaited(
                  _update(entry, entry.copyWith(mealType: mealType)),
                ),
                onPickLoggedAt: () => unawaited(_pickLoggedDay(entry)),
                onPickAmount: entry.isBundle
                    ? null
                    : () => unawaited(_pickAmount(entry)),
                onEatAgain: () => unawaited(
                  CalorieEntryDetailsActions.eatAgain(
                    context,
                    controller: _controller,
                    repeated: repeatCalorieEntry(
                      entry,
                      id: const Uuid().v4(),
                      now: ref.read(clockProvider)(),
                    ),
                  ),
                ),
                onReturnToInventory: () => unawaited(
                  CalorieEntryDetailsActions.remove(
                    context,
                    controller: _controller,
                    entry: entry,
                  ),
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: SizedBox.square(
                dimension: AppSizes.inlineProgressIndicator,
                child: CircularProgressIndicator(
                  strokeWidth: AppSizes.progressStrokeWidth,
                ),
              ),
            ),
          ),
          error: (error, stackTrace) =>
              _MessageScaffold(message: l10n.caloriesLoadFailed),
        );
  }

  void _close() {
    if (ref.read(calorieEntryEditorControllerProvider)) {
      return;
    }
    CalorieEntryEditorFlowHandler.maybePopRootNavigator(
      context,
      isEditing: true,
    );
  }

  Future<void> _update(CalorieEntry previous, CalorieEntry updated) async {
    final next = updated.copyWith(updatedAt: ref.read(clockProvider)());
    setState(() => _pending = next);
    final provider = calorieEntryByIdProvider(widget.entryId);
    final container = ProviderScope.containerOf(context, listen: false);

    final saved = await CalorieEntryDetailsActions.saveChange(
      context,
      controller: _controller,
      previous: previous,
      updated: next,
      onUndone: () => container.invalidate(provider),
    );
    if (!mounted) {
      return;
    }
    if (!saved) {
      setState(() => _pending = null);
      return;
    }
    ref.invalidate(provider);
  }

  /// Moves the entry to another day. The time stays; the meal is chosen
  /// separately.
  Future<void> _pickLoggedDay(CalorieEntry entry) async {
    final current = entry.loggedAt;
    final date = await showCalorieEntryDatePicker(
      context,
      initialDate: current,
    );
    if (date == null || !mounted || DateUtils.isSameDay(date, current)) {
      return;
    }
    final loggedAt = DateTime(
      date.year,
      date.month,
      date.day,
      current.hour,
      current.minute,
    );
    await _update(entry, entry.copyWith(loggedAt: loggedAt));
  }

  Future<void> _pickAmount(CalorieEntry entry) async {
    if (!canEditCalorieEntryAmount(entry)) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.caloriesEntryAmountLockedMessage)),
        );
      return;
    }
    final amount = await showCalorieEntryAmountDialog(context, entry: entry);
    if (amount == null || !mounted) {
      return;
    }
    final now = ref.read(clockProvider)();
    await _update(entry, rescaleCalorieEntry(entry, amount: amount, now: now));
  }
}

class _MessageScaffold extends StatelessWidget {
  const new({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.caloriesEntryDetailsTitle),
      ),
      body: Center(child: Text(message)),
    );
  }
}
