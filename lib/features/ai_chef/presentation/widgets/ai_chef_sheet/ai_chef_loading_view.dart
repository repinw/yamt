import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Wir stellen ein Rezept zusammen …" with the app's progress indicator and
/// one cooking quote, muted, while the recipe idea comes.
class AiChefLoadingView extends StatefulWidget {
  /// Creates a loading view.
  const new({super.key});

  @override
  State<AiChefLoadingView> createState() => _AiChefLoadingViewState();
}

class _AiChefLoadingViewState extends State<AiChefLoadingView> {
  // One quote for the whole wait: it lasts seconds.
  final double _pick = Random().nextDouble();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final quoteStyle = textTheme.bodyMedium?.copyWith(color: colors.muted);
    final quotes = [
      l10n.aiChefQuoteLoveGarlic,
      l10n.aiChefQuoteCookingMagic,
      l10n.aiChefQuoteGoodFood,
      l10n.aiChefQuoteKitchenTalks,
    ];

    // A modal sheet is only as wide as its content: without the full width
    // the sheet would follow the length of the quote.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.aiChefGeneratingTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Two lines kept for every quote, so a short one leaves the sheet
          // as tall as a long one.
          Stack(
            alignment: Alignment.center,
            children: [
              Text('\n', style: quoteStyle),
              Text(
                quotes[(_pick * quotes.length).floor()],
                textAlign: TextAlign.center,
                style: quoteStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
