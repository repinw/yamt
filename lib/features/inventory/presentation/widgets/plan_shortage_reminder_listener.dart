import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/local_notifications.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/inventory/domain/plan_shortage_reminders.dart';
import 'package:yamt/features/inventory/presentation/controllers/plan_shortage_reminder_controller.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';
import 'package:yamt/features/shoppinglist/presentation/shopping_plan_needs_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Keeps the day-before reminders for missing plan ingredients scheduled,
/// and asks again when the user taps one: the missing ingredients go on the
/// shopping list after the tap. Wraps the app below its `ScaffoldMessenger`.
class PlanShortageReminderListener extends ConsumerStatefulWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  ConsumerState<PlanShortageReminderListener> createState() =>
      _PlanShortageReminderListenerState();
}

class _PlanShortageReminderListenerState
    extends ConsumerState<PlanShortageReminderListener> {
  late final GoRouter _router = ref.read(appRouterProvider);
  late final StreamSubscription<String> _taps;
  DateTime? _pendingDay;
  // iOS may hand the tap that launched the app over twice.
  final _askedDays = <DateTime>{};

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_showWhenHome);
    _taps = ref.read(localNotificationsProvider).taps.listen(
      (payload) {
        _pendingDay = planShortageReminderDay(payload) ?? _pendingDay;
        _showWhenHome();
      },
      onError: (Object error, StackTrace stackTrace) => log(
        'Reading notification taps failed.',
        name: 'PlanShortageReminderListener',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_showWhenHome);
    unawaited(_taps.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(planShortageReminderPlanProvider, (_, next) {
      // A failed read keeps the scheduled reminders; the next change syncs.
      if (next case AsyncData(value: final reminders)) {
        unawaited(
          ref.read(planShortageReminderControllerProvider.notifier).sync(
            reminders,
            (
              channelName: l10n.planShortageReminderChannelName,
              title: l10n.planShortageReminderTitle,
              body: l10n.planShortageReminderBody,
            ),
          ),
        );
      }
    });
    return widget.child;
  }

  // A tap that launches the app arrives before sign-in is done.
  void _showWhenHome() {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (_pendingDay == null || !path.startsWith(AppRoutes.home)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final day = _pendingDay;
      _pendingDay = null;
      if (day != null && mounted && _askedDays.add(day)) {
        unawaited(_ask(day));
      }
    });
  }

  Future<void> _ask(DateTime day) async {
    final controller = ref.read(
      planShortageReminderControllerProvider.notifier,
    );
    List<ShoppingPlanNeed>? needs;
    try {
      needs = await controller.missingFor(day);
    } on Object catch (error, stackTrace) {
      log(
        'Reading the missing plan ingredients failed.',
        name: 'PlanShortageReminderListener',
        error: error,
        stackTrace: stackTrace,
      );
    }
    // The listener sits above the navigator, so the question opens on it.
    final navigator = ref.read(navigatorKeyProvider).currentContext;
    if (!mounted || navigator == null || !navigator.mounted) {
      return;
    }
    if (needs == null) {
      ScaffoldMessenger.of(navigator).showAppSnackBar(
        AppLocalizations.of(navigator)!.planShortageReminderCheckFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    // Answered as soon as it is shown, whatever the answer.
    unawaited(controller.quietDay(day));
    if (needs.isEmpty) {
      ScaffoldMessenger.of(navigator).showAppSnackBar(
        AppLocalizations.of(navigator)!.planShortageReminderAllThere,
        tone: AppSnackBarTone.info,
      );
      return;
    }
    final neverAsk = await ShoppingPlanNeedsFlow.offer(
      navigator,
      needs,
      isCancelled: () => false,
      offerNeverAsk: true,
    );
    if (neverAsk && mounted) {
      await ref
          .read(planShortageReminderControllerProvider.notifier)
          .setEnabled(enabled: false);
    }
  }
}
