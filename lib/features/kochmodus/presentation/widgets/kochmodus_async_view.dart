import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/kitchen_utensils/application/kitchen_utensil_list_provider.dart';
import 'package:yamt/features/kochmodus/presentation/controllers/kochmodus_controller.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The cooking of [target] while it loads, failed, or is gone, else [data].
/// Says that the cooking could not be saved when the server rejects it.
class KochmodusAsyncView extends ConsumerWidget {
  /// Creates the view that shows [data] of the cooking of [target].
  const new({required this.target, required this.data, super.key});

  /// Key of "Zum Kochbuch" when the run or recipe is gone.
  static const goneBackKey = ValueKey<String>('kochmodus-gone-back');

  /// What the page cooks.
  final KochmodusTarget target;

  /// The page of the cooking as it is now; not after it ended elsewhere.
  final Widget Function(KochmodusView view) data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final provider = kochmodusControllerProvider(target);
    ref.listen(provider, (previous, next) {
      final before = previous?.value?.rejected ?? 0;
      if ((next.value?.rejected ?? 0) > before) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          l10n.kochmodusSaveFailed,
          tone: AppSnackBarTone.error,
        );
      }
    });
    return ref
        .watch(provider)
        .when(
          // A source that reloads keeps the page and what its widgets
          // hold, such as the line heard last.
          skipLoadingOnReload: true,
          data: (view) => switch (view) {
            null || KochmodusView(ended: true, finished: null) =>
              const _KochmodusGone(),
            _ => data(view),
          },
          loading: () => const AppLoadingView(),
          error: (_, _) => AppErrorRetryView(
            message: l10n.kochmodusLoadFailed,
            retryLabel: l10n.inventoryRetryAction,
            onRetry: () => ref
              ..invalidate(cookRunsProvider)
              ..invalidate(inventoryQuickEatItemsProvider)
              ..invalidate(kitchenUtensilListProvider)
              ..invalidate(provider),
          ),
        );
  }
}

/// The recipe or the run is gone: finished or discarded elsewhere, or
/// never there.
class _KochmodusGone extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: AppInsets.pageLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xl,
          children: [
            Text(l10n.kochmodusGone, textAlign: TextAlign.center),
            OutlinedButton(
              key: KochmodusAsyncView.goneBackKey,
              onPressed: () => context.pop(),
              child: Text(l10n.kochmodusBackToCookbook),
            ),
          ],
        ),
      ),
    );
  }
}
