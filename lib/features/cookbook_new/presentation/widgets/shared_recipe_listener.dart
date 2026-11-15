import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/device/pending_shared_text.dart';
import 'package:yamt/core/device/pending_unreadable_share.dart';
import 'package:yamt/core/router/app_router.dart';
import 'package:yamt/core/widgets/app_snack_bar.dart';
import 'package:yamt/features/cookbook_new/domain/shared_recipe_link.dart';
import 'package:yamt/features/cookbook_new/presentation/models/'
    'recipe_editor_route_args.dart';
import 'package:yamt/features/cookbook_new/presentation/recipe_link_flow.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Takes text that another app shares with yamt as a recipe, once the app
/// shows its home pages: a link is read like "Aus Link", other text opens the
/// editor of a new recipe with the text pasted, and a share we could not read
/// gets a message.
class SharedRecipeListener extends ConsumerStatefulWidget {
  /// Creates the listener above [child].
  const new({required this.child, super.key});

  /// The key of the message about a share we could not read.
  static const unreadableKey = ValueKey<String>('shared-recipe-unreadable');

  /// The app below the listener.
  final Widget child;

  @override
  ConsumerState<SharedRecipeListener> createState() =>
      _SharedRecipeListenerState();
}

class _SharedRecipeListenerState extends ConsumerState<SharedRecipeListener> {
  late final ProviderSubscription<String?> _textSubscription;
  late final ProviderSubscription<bool> _unreadableSubscription;
  late final ProviderSubscription<GoRouter> _routerSubscription;

  /// The router whose delegate [_check] listens to.
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _textSubscription = ref.listenManual(
      pendingSharedTextProvider,
      (_, _) => _check(),
    );
    _unreadableSubscription = ref.listenManual(
      pendingUnreadableShareProvider,
      (_, _) => _check(),
    );
    // A text shared while the app is not on its home pages (start, data
    // key, required update, a load failure) waits until it gets there.
    _routerSubscription = ref.listenManual(appRouterProvider, (_, next) {
      _router?.routerDelegate.removeListener(_check);
      _router = next..routerDelegate.addListener(_check);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_check);
    _routerSubscription.close();
    _unreadableSubscription.close();
    _textSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  /// Looks for a shared text after the frame that applies the route. Until
  /// then the navigator still holds the old page, and a dialog shown on it
  /// would go away with that page.
  void _check() {
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _takeWhenReady())
      ..scheduleFrame();
  }

  void _takeWhenReady() {
    if (!mounted) {
      return;
    }
    final navContext = ref.read(navigatorKeyProvider).currentContext;
    if (navContext == null ||
        !navContext.mounted ||
        (ref.read(pendingSharedTextProvider) == null &&
            !ref.read(pendingUnreadableShareProvider))) {
      return;
    }
    final router = ref.read(appRouterProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path != AppRoutes.home && !path.startsWith('${AppRoutes.home}/')) {
      return;
    }
    if (ref.read(pendingUnreadableShareProvider.notifier).take()) {
      ScaffoldMessenger.of(navContext).showAppSnackBar(
        AppLocalizations.of(navContext)!.recipeShareUnreadable,
        tone: AppSnackBarTone.error,
        key: SharedRecipeListener.unreadableKey,
      );
    }
    final text = ref.read(pendingSharedTextProvider.notifier).take();
    if (text == null) {
      return;
    }
    if (sharedRecipeLink(text) case final link?) {
      unawaited(RecipeLinkFlow.read(navContext, ref, link));
      return;
    }
    unawaited(
      navContext.push(
        AppRoutes.homeRecipeNew,
        extra: RecipeEditorRouteArgs(sharedText: text),
      ),
    );
  }
}
