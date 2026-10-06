import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/diary/presentation/controllers/'
    'diary_quick_entry_controller.dart';
import 'package:yamt/features/diary/presentation/models/'
    'diary_quick_entry_result.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_quick_entry_label.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_page_scaffold.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_text_link.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/'
    'eat_when_menu.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Quick entry: calories, and optionally a name and macros, typed in by hand
/// without a food. It pops with a [DiaryQuickEntryResult].
class DiaryQuickEntryPage extends ConsumerStatefulWidget {
  /// Creates the page for the given day and meal.
  const new({
    required this.initialLoggedAt,
    required this.initialMealType,
    super.key,
  });

  /// Key of the confirm button.
  static const confirmKey = Key('diary_quick_entry_confirm_button');

  /// Key of the close button.
  static const closeKey = Key('diary_quick_entry_close_button');

  /// Key of the name input.
  static const nameKey = Key('diary_quick_entry_name_field');

  /// Key of the hint that the AI estimate is more precise.
  static const aiHintKey = Key('diary_quick_entry_ai_hint');

  /// Key of the button that opens the AI estimate.
  static const aiButtonKey = Key('diary_quick_entry_ai_button');

  /// Preselected log time.
  final DateTime initialLoggedAt;

  /// Preselected meal.
  final MealType initialMealType;

  @override
  ConsumerState<DiaryQuickEntryPage> createState() =>
      _DiaryQuickEntryPageState();
}

class _DiaryQuickEntryPageState extends ConsumerState<DiaryQuickEntryPage> {
  late final DiaryQuickEntryControllerProvider _provider =
      diaryQuickEntryControllerProvider(
        initialLoggedAt: widget.initialLoggedAt,
        initialMealType: widget.initialMealType,
      );
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final Map<DiaryQuickEntryValue, TextEditingController> _texts = {
    for (final value in DiaryQuickEntryValue.values)
      value: TextEditingController(),
  };
  final Map<DiaryQuickEntryValue, FocusNode> _focusNodes = {
    for (final value in DiaryQuickEntryValue.values) value: FocusNode(),
  };

  DiaryQuickEntryController get _controller => ref.read(_provider.notifier);

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    for (final controller in _texts.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(_provider);

    return EatPageScaffold(
      // A failed save shows its snack bar on this page.
      hasOwnMessenger: false,
      whenControl: EatWhenMenu(
        loggedAt: state.loggedAt,
        today: state.today,
        mealType: state.mealType,
        onDayPicked: (day) => _controller.setLoggedDay(day),
        onMealTypeChanged: (mealType) => _controller.setMealType(mealType),
      ),
      kcal: state.kcal,
      confirmButtonKey: DiaryQuickEntryPage.confirmKey,
      onConfirm: state.canSave ? _save : null,
      confirmHint: state.kcal == null ? l10n.diaryQuickEntryKcalMissing : null,
      cancelButtonKey: DiaryQuickEntryPage.closeKey,
      children: [
        _NameInput(
          controller: _name,
          focusNode: _nameFocus,
          hint: l10n.diaryQuickEntryDefaultName,
          onChanged: (name) => _controller.setName(name),
          onSubmitted: () =>
              _focusNodes[DiaryQuickEntryValue.values.first]!.requestFocus(),
        ),
        DiaryQuickEntryLabel(
          texts: _texts,
          focusNodes: _focusNodes,
          onChanged: (value, text) => _controller.setValueText(value, text),
          onSubmitted: _focusNext,
        ),
        if (state.isMissingMacros) _AiHint(onPressed: _openAi),
      ],
    );
  }

  void _focusNext(DiaryQuickEntryValue value) {
    const values = DiaryQuickEntryValue.values;
    if (value.index == values.length - 1) {
      _focusNodes[value]!.unfocus();
      return;
    }
    _focusNodes[values[value.index + 1]]!.requestFocus();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = AppLocalizations.of(context)!;
    final isPlan = ref.read(_provider).isPlan;
    final entry = await _controller.save(
      defaultName: l10n.diaryQuickEntryDefaultName,
    );
    if (!mounted) {
      return;
    }
    if (entry == null) {
      ScaffoldMessenger.of(
        context,
      ).showAppSnackBar(l10n.caloriesSaveFailed, tone: AppSnackBarTone.error);
      return;
    }
    Navigator.of(context).pop(DiaryQuickEntrySaved(entry, isPlan: isPlan));
  }

  void _openAi() {
    final state = ref.read(_provider);
    Navigator.of(context).pop(
      DiaryQuickEntryAiRequested(
        loggedAt: state.loggedAt,
        mealType: state.mealType,
      ),
    );
  }
}

/// The name as a big borderless input with a quiet underline, like the name
/// on the eat page.
class _NameInput extends StatelessWidget {
  const new({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final style = Theme.of(context).textTheme.headlineMedium
        ?.copyWith(fontWeight: FontWeight.w800, color: colors.ink);

    return TextField(
      key: DiaryQuickEntryPage.nameKey,
      controller: controller,
      focusNode: focusNode,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.next,
      cursorColor: colors.ink,
      style: style,
      onChanged: onChanged,
      onSubmitted: (_) => onSubmitted(),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: style?.copyWith(color: colors.muted),
        contentPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.rule),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: colors.ink,
            width: AppFoodLabel.outline,
          ),
        ),
      ),
    );
  }
}

/// Quiet note that macros left empty count as 0 g, with a link to the AI
/// estimate.
class _AiHint extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);

    return Column(
      key: DiaryQuickEntryPage.aiHintKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.diaryQuickEntryAiHint,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.muted),
        ),
        EatTextLink(
          buttonKey: DiaryQuickEntryPage.aiButtonKey,
          label: l10n.diaryQuickEntryAiAction,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
