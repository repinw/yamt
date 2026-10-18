import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What a recipe page shows of [value], which loads with the recipe and the
/// Vorrat: [data] once both are there, "Rezept nicht gefunden" when the
/// recipe is gone, and a retry that loads both again after a failure.
class RecipeAsyncView<T extends Object> extends ConsumerWidget {
  /// Creates the view.
  const new({
    required this.value,
    required this.data,
    this.notFoundKey,
    this.retryKey,
    super.key,
  });

  /// The page's view of the recipe, `null` when the recipe is gone.
  final AsyncValue<T?> value;

  /// Builds the page for the loaded view.
  final Widget Function(T view) data;

  /// Key of the "Rezept nicht gefunden" text.
  final Key? notFoundKey;

  /// Key of the retry button.
  final Key? retryKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return value.when(
      data: (view) => switch (view) {
        final view? => data(view),
        null => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Text(
              l10n.recipeNotFound,
              key: notFoundKey,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      },
      error: (_, _) => AppErrorRetryView(
        retryButtonKey: retryKey,
        message: l10n.recipeLoadFailed,
        retryLabel: l10n.inventoryRetryAction,
        onRetry: () => ref
            .read(cookbookControllerProvider(l10n.localeName).notifier)
            .retry(),
      ),
      loading: () => const AppLoadingView(),
    );
  }
}
