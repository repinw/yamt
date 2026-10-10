import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/screen_wake_lock.dart';
import 'package:yamt/core/device/voice_search_service.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/core/widgets/voice_input_state_mixin.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'free_cooking_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooking_voice_input_mixin.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'cooking_voice_zone.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_discard_dialog.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_row_list.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Frei kochen": a meal without a recipe. The cook says or types the
/// ingredients while cooking, sees which ones the Vorrat holds, and "Kochen"
/// saves the meal in the Vorrat with the missing rows left open, then opens
/// the "Gekocht" step.
class FreeCookingPage extends ConsumerStatefulWidget {
  /// Creates the page.
  const new({super.key});

  /// Key of the voice zone.
  static const voiceZoneKey = ValueKey<String>('free-cooking-voice');

  /// Key of the retry button after the Vorrat failed to load.
  static const retryKey = ValueKey<String>('free-cooking-retry');

  @override
  ConsumerState<FreeCookingPage> createState() => _FreeCookingPageState();
}

class _FreeCookingPageState extends ConsumerState<FreeCookingPage>
    with
        VoiceInputStateMixin<FreeCookingPage>,
        CookingVoiceInputMixin<FreeCookingPage> {
  @override
  late final VoiceSearchService voiceService;
  late final ScreenWakeLock _wakeLock;
  final _nameController = TextEditingController();
  bool _isCooking = false;

  @override
  void initState() {
    super.initState();
    voiceService = ref.read(voiceSearchServiceProvider);
    _wakeLock = ref.read(screenWakeLockProvider)..acquire();
  }

  @override
  void dispose() {
    cancelListening();
    _nameController.dispose();
    _wakeLock.release();
    super.dispose();
  }

  @override
  bool get pausesVoiceInput => _isCooking;

  @override
  void onSpokenText(String text) => _addText(text);

  void _addText(String text) {
    ref.read(freeCookingControllerProvider.notifier).addText(text);
  }

  Future<void> _cook() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final typedName = _nameController.text.trim();
    final name = typedName.isEmpty ? l10n.freeCookingDefaultName : typedName;
    setState(() => _isCooking = true);
    // What the cook is still saying belongs to the meal.
    await finishListening();
    if (!mounted) {
      return;
    }
    final rows = ref.read(freeCookingRowsProvider(l10n.localeName)).value;
    final mealId = rows == null || rows.isEmpty
        ? null
        : await ref
              .read(freeCookingControllerProvider.notifier)
              .cook(name: name, rows: rows);
    if (!mounted) {
      return;
    }
    setState(() => _isCooking = false);
    if (mealId == null) {
      messenger.showAppSnackBar(
        l10n.freeCookingSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    // Straight on to the "Gekocht" step; closing it leaves the meal in the pot.
    context.pushReplacement(AppRoutes.homeCookedMealPath(mealId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final draft = ref.watch(freeCookingControllerProvider);
    final rowsAsync = ref.watch(freeCookingRowsProvider(l10n.localeName));
    final rows = rowsAsync.value ?? const <FreeCookingRow>[];
    final isBusy = draft.isCooking || _isCooking;
    final canCook = !isBusy && !rowsAsync.hasError && rows.isNotEmpty;

    return PopScope(
      canPop: draft.rows.isEmpty && !isBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isBusy) {
          unawaited(_confirmDiscard());
        }
      },
      child: Scaffold(
        backgroundColor: colors.paper,
        // The name field sits at the top, so the keyboard may cover the
        // voice zone and the actions instead of squeezing them.
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FreeCookingHeader(nameController: _nameController, rows: rows),
              Expanded(
                child: rowsAsync.when(
                  data: (rows) => FreeCookingRowList(
                    rows: rows,
                    pendingText: pendingSpeech,
                    onRemove: (index) => ref
                        .read(freeCookingControllerProvider.notifier)
                        .removeRow(index),
                  ),
                  loading: () => const AppLoadingView(),
                  error: (_, _) => AppErrorRetryView(
                    retryButtonKey: FreeCookingPage.retryKey,
                    message: l10n.freeCookingStockLoadFailed,
                    retryLabel: l10n.inventoryRetryAction,
                    onRetry: () => ref
                        .read(freeCookingControllerProvider.notifier)
                        .retryStock(),
                  ),
                ),
              ),
              CookingVoiceZone(
                key: FreeCookingPage.voiceZoneKey,
                isListening: isListening,
                idleHint: l10n.freeCookingIdleHint,
                onPressed: isBusy ? null : () => unawaited(toggleListening()),
              ),
              FreeCookingActions(
                isCooking: isBusy,
                onType: () => unawaited(typeText()),
                onCook: canCook ? () => unawaited(_cook()) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    // A back gesture opens the dialog without a tap outside the name, which
    // would otherwise take the focus back when the dialog closes.
    FocusManager.instance.primaryFocus?.unfocus();
    final discard = await showFreeCookingDiscardDialog(context);
    if (discard && mounted) {
      context.pop();
    }
  }
}
