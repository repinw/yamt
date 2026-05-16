import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/experimental/scope.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_responsive_viewport.dart';
import 'package:yamt/features/home/widgets/home_shell_chrome.dart'
    show HomeTabType;
import 'package:yamt/features/home/widgets/home_shell_tab_top_chrome.dart';
import 'package:yamt/features/inventory/data/'
    'inventory_activity_event_repository.dart';
import 'package:yamt/features/inventory/domain/inventory_activity_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Inventory activity timeline.
@Dependencies([inventoryActivityEvents])
class InventoryActivityTimeline extends ConsumerWidget {
  /// Creates timeline.
  const InventoryActivityTimeline({
    required this.includeHomeShellChrome,
    required this.topChromeActions,
    super.key,
  });

  /// Whether to render home shell chrome.
  final bool includeHomeShellChrome;

  /// Actions rendered in home shell chrome.
  final List<Widget> topChromeActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final eventsAsync = ref.watch(inventoryActivityEventsProvider);
    return CustomScrollView(
      slivers: [
        if (includeHomeShellChrome)
          HomeShellTabTopChrome(
            tab: HomeTabType.inventory,
            actions: topChromeActions,
          ),
        switch (eventsAsync) {
          AsyncData(:final value) => _buildDataSliver(
            context: context,
            l10n: l10n,
            events: value,
          ),
          AsyncError() => _buildMessageSliver(
            context: context,
            title: l10n.inventoryActivityLoadFailed,
            actionLabel: l10n.inventoryRetryAction,
            onAction: () => ref.invalidate(inventoryActivityEventsProvider),
          ),
          _ => _buildMessageSliver(
            context: context,
            title: l10n.inventoryActivityLoading,
          ),
        },
      ],
    );
  }

  Widget _buildDataSliver({
    required BuildContext context,
    required AppLocalizations l10n,
    required List<InventoryActivityEvent> events,
  }) {
    if (events.isEmpty) {
      return _buildMessageSliver(
        context: context,
        title: l10n.inventoryActivityEmptyTitle,
      );
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayFormat = DateFormat.yMMMd(locale);
    final timeFormat = DateFormat.Hm(locale);
    final groupedEvents = _groupEventsByDay(events);
    final horizontalPadding = responsivePageHorizontalPadding(context);

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.lg,
        horizontalPadding,
        AppSpacing.xl,
      ),
      sliver: SliverList.separated(
        itemCount: groupedEvents.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final group = groupedEvents[index];
          return _InventoryActivityDayGroup(
            title: dayFormat.format(group.day),
            timeFormat: timeFormat,
            events: group.events,
            l10n: l10n,
          );
        },
      ),
    );
  }

  Widget _buildMessageSliver({
    required BuildContext context,
    required String title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final horizontalPadding = responsivePageHorizontalPadding(context);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: onAction,
                  child: Text(actionLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryActivityDayGroup extends StatelessWidget {
  const _InventoryActivityDayGroup({
    required this.title,
    required this.timeFormat,
    required this.events,
    required this.l10n,
  });

  final String title;
  final DateFormat timeFormat;
  final List<InventoryActivityEvent> events;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              for (var index = 0; index < events.length; index += 1) ...[
                _InventoryActivityTile(
                  event: events[index],
                  timeFormat: timeFormat,
                  l10n: l10n,
                ),
                if (index < events.length - 1)
                  Divider(height: 1, color: colors.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InventoryActivityTile extends StatelessWidget {
  const _InventoryActivityTile({
    required this.event,
    required this.timeFormat,
    required this.l10n,
  });

  final InventoryActivityEvent event;
  final DateFormat timeFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconForType(event.type)),
      title: Text(_titleForEvent(l10n, event)),
      subtitle: Text(timeFormat.format(event.happenedAt)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
    );
  }
}

class _InventoryActivityDay {
  const _InventoryActivityDay({required this.day, required this.events});

  final DateTime day;
  final List<InventoryActivityEvent> events;
}

List<_InventoryActivityDay> _groupEventsByDay(
  List<InventoryActivityEvent> events,
) {
  final groups = <DateTime, List<InventoryActivityEvent>>{};
  for (final event in events) {
    final day = DateUtils.dateOnly(event.happenedAt);
    groups.putIfAbsent(day, () => <InventoryActivityEvent>[]).add(event);
  }
  return groups.entries
      .map(
        (entry) => _InventoryActivityDay(day: entry.key, events: entry.value),
      )
      .toList(growable: false);
}

IconData _iconForType(InventoryActivityEventType type) {
  return switch (type) {
    InventoryActivityEventType.itemAdded => Icons.add,
    InventoryActivityEventType.itemConsumed => Icons.restaurant,
    InventoryActivityEventType.itemDiscarded => Icons.delete_outline,
    InventoryActivityEventType.itemDeleted => Icons.remove_circle_outline,
    InventoryActivityEventType.itemRestored => Icons.restore,
    InventoryActivityEventType.itemUsedInPreparedMeal => Icons.soup_kitchen,
    InventoryActivityEventType.itemReturnedFromPreparedMeal => Icons.undo,
  };
}

String _titleForEvent(
  AppLocalizations l10n,
  InventoryActivityEvent event,
) {
  final actor = event.actorDisplayName ?? l10n.inventoryActivityActorFallback;
  final amount = _amountLabel(l10n, event);
  return switch (event.type) {
    InventoryActivityEventType.itemAdded => l10n.inventoryActivityItemAdded(
      actor,
      event.itemName,
      amount,
    ),
    InventoryActivityEventType.itemConsumed =>
      l10n.inventoryActivityItemConsumed(actor, event.itemName, amount),
    InventoryActivityEventType.itemDiscarded =>
      l10n.inventoryActivityItemDiscarded(actor, event.itemName, amount),
    InventoryActivityEventType.itemDeleted => l10n.inventoryActivityItemDeleted(
      actor,
      event.itemName,
      amount,
    ),
    InventoryActivityEventType.itemRestored =>
      l10n.inventoryActivityItemRestored(actor, event.itemName, amount),
    InventoryActivityEventType.itemUsedInPreparedMeal =>
      l10n.inventoryActivityItemUsedInPreparedMeal(
        actor,
        event.itemName,
        amount,
      ),
    InventoryActivityEventType.itemReturnedFromPreparedMeal =>
      l10n.inventoryActivityItemReturnedFromPreparedMeal(
        actor,
        event.itemName,
        amount,
      ),
  };
}

String _amountLabel(
  AppLocalizations l10n,
  InventoryActivityEvent event,
) {
  final unit = event.itemAmountUnit;
  if (unit == null) {
    return l10n.inventoryActivityPieceAmount(event.amount);
  }
  final value = formatInventoryAmountValue(
    amount: event.amount,
    unit: unit,
    scale: event.amountScale,
  );
  return '$value ${unit.code}';
}
