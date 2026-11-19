import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/widgets/home_header_tool.dart';
import 'package:yamt/features/shoppinglist/presentation/controllers/shopping_open_count.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Header tool of a home tab that opens the shopping list. A badge counts the
/// entries still to buy, on the household list and the private list
/// together. While the count loads the tool shows no badge; when the list
/// cannot be read it shows without a badge, so the list stays reachable.
class ShoppingHeaderTool extends ConsumerWidget {
  /// Creates the tool. With [onlyWithOpenEntries] it shows only while an
  /// entry is still to buy, or while that is unknown after a failed read.
  const new({this.onlyWithOpenEntries = false, super.key});

  /// Whether the tool hides while nothing is left to buy.
  final bool onlyWithOpenEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(openShoppingListCountProvider);
    final count = countAsync.hasError ? null : countAsync.value ?? 0;
    if (onlyWithOpenEntries && count == 0) {
      return const SizedBox.shrink();
    }
    return HomeHeaderTool(
      symbol: const Icon(Icons.shopping_cart_rounded),
      label: AppLocalizations.of(context)!.homeShopping,
      badgeCount: count == null || count == 0 ? null : count,
      onPressed: () => unawaited(context.push(AppRoutes.homeShopping)),
    );
  }
}
