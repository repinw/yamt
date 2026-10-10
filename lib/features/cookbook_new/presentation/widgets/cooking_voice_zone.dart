import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The large tap zone that starts and stops listening, big enough to hit
/// with dirty hands while cooking.
class CookingVoiceZone extends StatelessWidget {
  /// Creates the zone.
  const new({
    required this.isListening,
    required this.onPressed,
    required this.idleHint,
    super.key,
  });

  /// Whether the microphone is listening.
  final bool isListening;

  /// Starts or stops listening; `null` while the meal is saving.
  final VoidCallback? onPressed;

  /// What to say, shown while the microphone is off.
  final String idleHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppGraphit.voiceZoneMinHeight,
        ),
        child: Material(
          color: colors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(
              color: isListening ? colors.ink : colors.rule,
              width: AppGraphit.highlightUnderline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AppInkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: AppSpacing.md,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening ? colors.ink : colors.accent,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Icon(
                        isListening
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_rounded,
                        size: AppGraphit.voiceZoneIcon,
                        color: isListening ? colors.paper : colors.onAccent,
                      ),
                    ),
                  ),
                  Text(
                    isListening
                        ? l10n.freeCookingListenTitle
                        : l10n.freeCookingIdleTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isListening ? l10n.freeCookingListenHint : idleHint,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
