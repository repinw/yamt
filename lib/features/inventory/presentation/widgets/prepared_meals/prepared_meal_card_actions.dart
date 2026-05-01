part of 'prepared_meal_card.dart';

@Dependencies([InventoryItemsController, preparedMealImagePicker])
mixin _PreparedMealCardActions on ConsumerState<PreparedMealCard> {
  bool get expandedState;
  set expandedState(bool value);

  bool get workingState;
  set workingState(bool value);

  void _toggleExpanded() {
    setState(() {
      expandedState = !expandedState;
    });
  }

  void _onEatPressed() {
    unawaited(_runEatFlow());
  }

  void _onThrowAwayPressed() {
    unawaited(_runThrowAwayFlow());
  }

  void _onFillPendingIngredient({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
  }) {
    unawaited(
      _runFillPendingIngredientFlow(
        ingredient: ingredient,
        inventoryItems: inventoryItems,
      ),
    );
  }

  void _onIgnorePendingIngredient(String ingredient) {
    unawaited(_runIgnorePendingIngredientFlow(ingredient: ingredient));
  }

  void _onEditPressed() {
    unawaited(_runEditFlow());
  }

  void _onUnbundlePressed() {
    unawaited(
      _runAction(
        () => widget.onUnbundlePressed(widget.meal.id),
        failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
      ),
    );
  }

  void _onSaveTemplatePressed() {
    unawaited(
      _runAction(
        () => widget.onSaveTemplatePressed(widget.meal),
        failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
      ),
    );
  }

  Future<void> _runEatFlow() async {
    final l10n = AppLocalizations.of(context)!;
    final imageRef = maybeLocalImageAssetRef(widget.meal.imageAssetId);
    final imageBytes = imageRef == null
        ? null
        : ref.read(localImageBytesProvider(imageRef)).asData?.value;
    final result = await showPreparedMealEatDialog(
      context,
      widget.meal,
      imageBytes: imageBytes,
    );
    if (!mounted || result == null) {
      return;
    }

    await _runAction(
      () => widget.onEatPressed(
        mealId: widget.meal.id,
        portions: result.portions,
        mealType: result.mealType,
        loggedDay: result.loggedDay,
      ),
      failureMessage: l10n.preparedMealActionFailed,
    );
  }

  Future<void> _runEditFlow() async {
    final result = await showPreparedMealEditSheet(
      context: context,
      meal: widget.meal,
    );
    if (!mounted || result == null) {
      return;
    }

    await _runAction(
      () => widget.onEditPressed(
        widget.meal.id,
        result.name,
        result.imageChanged,
        result.imageBytes,
      ),
      failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  Future<void> _runThrowAwayFlow() async {
    log(
      '_runThrowAwayFlow(): opening reason dialog for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );
    final reason = await showInventoryDiscardReasonDialog(context);
    if (!mounted || reason == null) {
      log(
        '_runThrowAwayFlow(): reason dialog cancelled for ${widget.meal.id}',
        name: _preparedMealCardLogName,
      );
      return;
    }
    log(
      '_runThrowAwayFlow(): confirmed reason=${reason.name} '
      'for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );

    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }

    log(
      '_runThrowAwayFlow(): opening portion dialog for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );
    final portions = await showPreparedMealPortionDialog(
      context: context,
      meal: widget.meal,
      title: AppLocalizations.of(context)!.preparedMealThrowAwayTitle,
    );
    if (!mounted || portions == null) {
      log(
        '_runThrowAwayFlow(): portion dialog cancelled for ${widget.meal.id}',
        name: _preparedMealCardLogName,
      );
      return;
    }
    log(
      '_runThrowAwayFlow(): confirmed portions=$portions for ${widget.meal.id}',
      name: _preparedMealCardLogName,
    );

    await _runAction(
      () => widget.onThrowAwayPressed(widget.meal.id, portions, reason),
      failureMessage: AppLocalizations.of(context)!.preparedMealActionFailed,
    );
  }

  Future<void> _runFillPendingIngredientFlow({
    required String ingredient,
    required List<InventoryItem> inventoryItems,
  }) async {
    if (widget.onFillPendingIngredientPressed == null) {
      return;
    }

    final selectedItemIds = await _showPendingIngredientSelectionSheet(
      context: context,
      ingredient: ingredient,
      inventoryItems: inventoryItems,
    );
    if (!mounted || selectedItemIds == null || selectedItemIds.isEmpty) {
      return;
    }

    await _runAction(
      () => widget.onFillPendingIngredientPressed!(
        widget.meal.id,
        ingredient,
        selectedItemIds,
      ),
      failureMessage: AppLocalizations.of(
        context,
      )!.preparedMealPendingIngredientFillFailed,
    );
  }

  Future<void> _runIgnorePendingIngredientFlow({
    required String ingredient,
  }) async {
    if (widget.onIgnorePendingIngredientPressed == null) {
      return;
    }

    await _runAction(
      () =>
          widget.onIgnorePendingIngredientPressed!(widget.meal.id, ingredient),
      failureMessage: AppLocalizations.of(
        context,
      )!.preparedMealPendingIngredientIgnoreFailed,
    );
  }

  Future<void> _runAction(
    Future<bool> Function() action, {
    required String failureMessage,
  }) async {
    setState(() {
      workingState = true;
    });
    final success = await action();
    if (!mounted) {
      return;
    }
    setState(() {
      workingState = false;
    });
    if (success) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}
