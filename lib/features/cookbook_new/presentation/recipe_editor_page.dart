import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_state_views.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'free_cooking_discard_dialog.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_form.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_flow_top_bar.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Writes a new recipe, or changes the saved recipe [recipeId]: photo, name,
/// portions, ingredient lines, and steps.
class RecipeEditorPage extends ConsumerStatefulWidget {
  /// Creates the editor; a new recipe without [recipeId].
  const new({
    this.recipeId,
    this.args = const RecipeEditorRouteArgs(),
    super.key,
  });

  /// Key of the close button.
  static const closeKey = ValueKey<String>('recipe-editor-close');

  /// Key of the retry button after a load failure.
  static const retryKey = ValueKey<String>('recipe-editor-retry');

  /// Key of "Rezept nicht gefunden".
  static const notFoundKey = ValueKey<String>('recipe-editor-not-found');

  /// The saved recipe to change; `null` for a new one.
  final String? recipeId;

  /// How a new recipe's editor starts.
  final RecipeEditorRouteArgs args;

  @override
  ConsumerState<RecipeEditorPage> createState() => _RecipeEditorPageState();
}

class _RecipeEditorPageState extends ConsumerState<RecipeEditorPage> {
  /// This editor's own draft: a new recipe's editor never shares it with
  /// another one, such as one that a shared text opens on top.
  late final String _editorId = widget.recipeId ?? const Uuid().v4();

  /// Whether a typed line waits in a field that adds lines.
  bool _hasPendingLine = false;

  void _setHasPendingLine(bool hasPendingLine) {
    if (hasPendingLine != _hasPendingLine) {
      setState(() => _hasPendingLine = hasPendingLine);
    }
  }

  Future<void> _confirmClose() async {
    final l10n = AppLocalizations.of(context)!;
    final discard = await showFreeCookingDiscardDialog(
      context,
      title: l10n.recipeEditorDiscardTitle,
      body: l10n.recipeEditorDiscardBody,
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final recipeId = widget.recipeId;
    final recipeUrl = widget.args.recipeUrl;
    final sharedText = widget.args.sharedText;
    final provider = recipeEditorControllerProvider(_editorId, recipeId);
    final value = ref.watch(provider);
    final editor = value.asData?.value;
    final isBusy = editor?.isBusy ?? false;
    final hasUnsaved = _hasPendingLine || (editor?.draft.hasChanges ?? false);

    // A scan or a save finishes before the page closes, and leaving unsaved
    // input asks first.
    return PopScope(
      canPop: !isBusy && !hasUnsaved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isBusy) unawaited(_confirmClose());
      },
      child: Scaffold(
        backgroundColor: FoodLabelColors.of(context).paper,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RecipeFlowTopBar(
                closeKey: RecipeEditorPage.closeKey,
                onClose: isBusy
                    ? null
                    : hasUnsaved
                    ? () => unawaited(_confirmClose())
                    : () => context.pop(),
                caption: switch (Uri.tryParse(recipeUrl ?? '')?.host) {
                  final host? when host.isNotEmpty => host.replaceFirst(
                    'www.',
                    '',
                  ),
                  _ when sharedText != null => l10n.recipeEditorSharedKicker,
                  _ when recipeId == null => l10n.cookbookNewRecipeTitle,
                  _ => l10n.recipeEditorEditTitle,
                },
              ),
              Expanded(
                child: value.when(
                  data: (editor) => editor == null
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Text(
                            l10n.recipeNotFound,
                            key: RecipeEditorPage.notFoundKey,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : RecipeEditorForm(
                          editorId: _editorId,
                          recipeId: recipeId,
                          args: widget.args,
                          onPendingChanged: _setHasPendingLine,
                        ),
                  error: (_, _) => AppErrorRetryView(
                    retryButtonKey: RecipeEditorPage.retryKey,
                    message: l10n.recipeLoadFailed,
                    retryLabel: l10n.inventoryRetryAction,
                    onRetry: () => ref.invalidate(provider),
                  ),
                  loading: () => const AppLoadingView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
