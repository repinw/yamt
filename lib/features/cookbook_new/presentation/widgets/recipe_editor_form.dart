import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_editor_draft.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/'
    'recipe_editor_controller.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_actions.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_header.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_lines.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_editor_scan_progress.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/'
    'recipe_link_failed_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The loaded recipe editor: photo, name, portions, the ingredient lines
/// and steps, and the scan, paste, and save actions.
class RecipeEditorForm extends ConsumerStatefulWidget {
  /// Creates the form for the editor [editorId] of [recipeId], which starts
  /// as [args] say.
  const new({
    required this.editorId,
    required this.recipeId,
    required this.args,
    required this.onPendingChanged,
    super.key,
  });

  /// The id of the open editor (see [RecipeEditorController]).
  final String editorId;

  /// The saved recipe to change; `null` for a new one.
  final String? recipeId;

  /// How a new recipe's editor starts. With the link of a page that could
  /// not be read, a card offers to read it again.
  final RecipeEditorRouteArgs args;

  /// Called with whether a typed line waits in a field that adds lines or
  /// in the line in edit.
  final ValueChanged<bool> onPendingChanged;

  @override
  ConsumerState<RecipeEditorForm> createState() => _RecipeEditorFormState();
}

class _RecipeEditorFormState extends ConsumerState<RecipeEditorForm> {
  late final TextEditingController _name;

  /// The typed lines that are not added yet, by list.
  final Map<RecipeEditorSection, TextEditingController> _pending = {
    for (final section in RecipeEditorSection.values)
      section: TextEditingController(),
  };

  /// Whether the line in edit holds a text it does not have yet.
  bool _editPending = false;

  RecipeEditorController get _controller => ref.read(
    recipeEditorControllerProvider(widget.editorId, widget.recipeId).notifier,
  );

  @override
  void initState() {
    super.initState();
    final editor = ref.read(
      recipeEditorControllerProvider(widget.editorId, widget.recipeId),
    );
    _name = TextEditingController(text: editor.value?.draft.name ?? '');
    for (final field in _pending.values) {
      field.addListener(_reportPending);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final args = widget.args;
      if (args.recipeUrl case final url?) _controller.setRecipeUrl(url);
      if (args.portions case final portions?) _controller.setPortions(portions);
      if (args.name.isNotEmpty) {
        _controller.setName(args.name);
        _showDraftName();
      }
      if (args.sharedText case final text?) {
        unawaited(_pasteText(text));
      }
      switch (args.start) {
        case RecipeEditorStart.blank:
          break;
        case RecipeEditorStart.scan:
          unawaited(_scan());
        case RecipeEditorStart.paste:
          unawaited(_paste());
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    for (final field in _pending.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _reportPending() => widget.onPendingChanged(
    _editPending ||
        _pending.values.any((field) => field.text.trim().isNotEmpty),
  );

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final read = await _controller.scan();
    if (!mounted) return;
    if (!read) {
      messenger.showAppSnackBar(
        l10n.recipeFromListScanFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    _showDraftName();
  }

  // A scan or paste names the recipe while it has no name; the field shows
  // it.
  void _showDraftName() {
    final name = ref
        .read(recipeEditorControllerProvider(widget.editorId, widget.recipeId))
        .value
        ?.draft
        .name;
    if (name != null && _name.text != name) _name.text = name;
  }

  Future<void> _paste() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    if (await _pasteText(clipboard?.text ?? '') == RecipePasteResult.empty) {
      messenger.showAppSnackBar(l10n.recipeEditorPasteEmpty);
    }
  }

  Future<RecipePasteResult> _pasteText(String text) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await _controller.paste(text);
    if (result == RecipePasteResult.tooLong) {
      messenger.showAppSnackBar(l10n.recipeEditorPasteTooLong);
    } else if (result == RecipePasteResult.read && mounted) {
      _showDraftName();
    }
    return result;
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final source = await chooseRecipePhotoSource(
      context,
      canUseCamera: _controller.canUseCamera(),
    );
    if (source == null || !mounted) return;
    final picked = await _controller.pickPhoto(
      camera: source == RecipePhotoSource.camera,
    );
    if (picked || !mounted) return;
    messenger.showAppSnackBar(
      l10n.preparedMealImagePickFailed,
      tone: AppSnackBarTone.error,
    );
  }

  /// [draft] with the typed lines that are not added yet.
  RecipeEditorDraft _withPending(RecipeEditorDraft draft) => _pending.entries
      .fold(draft, (draft, e) => draft.withAddedLines(e.key, [e.value.text]));

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Leaving the line in edit keeps its text before the draft is saved.
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    // A typed line counts without its own "done".
    for (final MapEntry(key: section, value: field) in _pending.entries) {
      if (field.text.trim().isNotEmpty) {
        _controller.addLine(section, field.text);
        field.clear();
      }
    }
    final recipeId = await _controller.save();
    if (!mounted) return;
    if (recipeId == null) {
      messenger.showAppSnackBar(
        l10n.recipeFromListSaveFailed,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    if (widget.recipeId == null) {
      context.pushReplacement(AppRoutes.homeRecipePath(recipeId));
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editor = ref
        .watch(recipeEditorControllerProvider(widget.editorId, widget.recipeId))
        .requireValue!;
    final draft = editor.draft;
    final failedLink = widget.args.recipeUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              if (editor.isScanning) const RecipeEditorScanProgress(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  0,
                ),
                child: RecipeEditorHeader(
                  nameController: _name,
                  onNameChanged: (name) => _controller.setName(name),
                  portions: draft.portions,
                  onPortionsChanged: (count) => _controller.setPortions(count),
                  photo: draft.photo,
                  original: draft.original,
                  onPhoto: () => unawaited(_pickPhoto()),
                ),
              ),
              // Until the cook has lines, say why the link gave none. A photo
              // or a typed line would not survive reading the page again, so
              // they take the offer away.
              if (failedLink != null && draft.photo == null)
                ListenableBuilder(
                  listenable: Listenable.merge(_pending.values),
                  builder: (context, _) => _withPending(draft).isEmpty
                      ? RecipeLinkFailedCard(
                          recipeUrl: failedLink,
                          name: draft.name,
                          portions: draft.portionsSetFrom(widget.args.portions),
                        )
                      : const SizedBox.shrink(),
                ),
              RecipeEditorLines(
                editorId: widget.editorId,
                recipeId: widget.recipeId,
                draft: draft,
                addControllers: _pending,
                onEditPendingChanged: (pending) {
                  _editPending = pending;
                  _reportPending();
                },
              ),
            ],
          ),
        ),
        ListenableBuilder(
          listenable: Listenable.merge(_pending.values),
          builder: (context, _) => RecipeEditorActions(
            draft: _withPending(draft),
            isSaving: editor.isSaving,
            onScan: editor.isBusy ? null : () => unawaited(_scan()),
            onPaste: editor.isBusy ? null : () => unawaited(_paste()),
            onSave: !editor.isBusy && _withPending(draft).canSave
                ? () => unawaited(_save())
                : null,
          ),
        ),
      ],
    );
  }
}
