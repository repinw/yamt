import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_import_controller.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_input_section.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_keys.dart';
import 'package:yamt/features/shoppinglist/presentation/widgets/shopping_import/shopping_import_review_section.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The list import: the user pastes or scans a list, we read it, and the
/// user checks the products before they go on the shopping list.
class ShoppingImportPage extends ConsumerStatefulWidget {
  /// Creates the import page.
  const new({super.key});

  @override
  ConsumerState<ShoppingImportPage> createState() => _ShoppingImportPageState();
}

class _ShoppingImportPageState extends ConsumerState<ShoppingImportPage> {
  // Kept here, so the text is still there when the user goes back from the
  // review.
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _restart() =>
      ref.read(shoppingImportControllerProvider.notifier).restart();

  void _retry() => ref.read(shoppingImportControllerProvider.notifier).retry();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final step = ref.watch(shoppingImportControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: step == null
            ? const CloseButton()
            : BackButton(onPressed: _restart),
        title: Text(
          step?.value == null
              ? l10n.shoppingImportTitle
              : l10n.shoppingImportReviewTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: step == null
            ? ShoppingImportInputSection(text: _text)
            : step.when(
                data: (review) => review.rows.isEmpty
                    ? _RetryView(
                        message: l10n.shoppingImportNothingFound,
                        onRetry: _retry,
                      )
                    : ShoppingImportReviewSection(review: review),
                loading: () => const _ReadingView(),
                error: (_, _) => _RetryView(
                  message: l10n.shoppingImportReadFailed,
                  onRetry: _retry,
                ),
              ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const new({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppErrorRetryView(
    message: message,
    retryLabel: AppLocalizations.of(context)!.shoppingImportRetry,
    retryButtonKey: ShoppingImportKeys.retryButton,
    onRetry: onRetry,
  );
}

class _ReadingView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Center(
    key: ShoppingImportKeys.reading,
    child: Padding(
      padding: AppInsets.pageLarge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingView(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppLocalizations.of(context)!.shoppingImportReading,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
