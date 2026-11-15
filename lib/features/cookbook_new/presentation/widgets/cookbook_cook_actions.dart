import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/home_action_entry.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Keys of the Kochbuch cook actions.
abstract final class CookbookCookActionKeys {
  /// Entry that starts free cooking.
  static const freeCooking = ValueKey<String>('cookbook-free-cooking');
}

/// The ways to start cooking: free cooking. New recipes start from the
/// Kochbuch header ("Neu").
List<HomeActionSection> cookbookCookActions(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    HomeActionSection(
      title: l10n.homeActionCook,
      entries: [
        HomeActionEntry(
          key: CookbookCookActionKeys.freeCooking,
          icon: Icons.mic_rounded,
          title: l10n.cookbookFreeCookingAction,
          description: l10n.cookbookFreeCookingDescription,
          onSelected: () =>
              unawaited(context.push<void>(AppRoutes.homeFreeCooking)),
        ),
      ],
    ),
  ];
}
