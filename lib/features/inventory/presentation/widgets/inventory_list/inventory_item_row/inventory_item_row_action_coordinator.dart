class InventoryItemRowActionCoordinator {
  const InventoryItemRowActionCoordinator({
    required this.isWorking,
    required this.setWorking,
    required this.isMounted,
    required this.showSnackBar,
    required this.defaultFailureMessage,
  });

  final bool Function() isWorking;
  final void Function(bool isWorking) setWorking;
  final bool Function() isMounted;
  final void Function(String message) showSnackBar;
  final String defaultFailureMessage;

  Future<void> runAction(
    Future<bool> Function() action, {
    String? successMessage,
    String? failureMessage,
  }) async {
    if (isWorking()) {
      return;
    }

    setWorking(true);
    final success = await action();
    if (!isMounted()) {
      return;
    }
    setWorking(false);

    if (success) {
      if (successMessage != null) {
        showSnackBar(successMessage);
      }
      return;
    }

    showSnackBar(failureMessage ?? defaultFailureMessage);
  }
}
