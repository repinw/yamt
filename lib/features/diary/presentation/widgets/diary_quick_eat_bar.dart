import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/diary/presentation/diary_quick_eat_flow.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_meals_section_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _animationDuration = Duration(milliseconds: 220);
const _expandedHeight = 88.0;
const _compactHeight = 44.0;

/// Barcode drawn with musical bar-line symbols.
const _barcodeGlyph = '𝄃𝄂𝄀𝄁𝄃𝄂𝄂𝄃';

/// Icon buttons that open the diary quick-eat sources.
///
/// Large with labels while the day is empty, compact glyph-only once food is
/// logged.
class DiaryQuickEatBar extends StatelessWidget {
  /// Creates the quick-eat bar.
  const new({required this.expanded, required this.onSelected, super.key});

  /// Whether to show large labeled buttons.
  final bool expanded;

  /// Called with the tapped source.
  final ValueChanged<DiaryQuickEatSource> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sources = [
      (
        DiaryQuickEatSource.inventory,
        // Same icon as the inventory tab in the home navigation bar.
        const Icon(Icons.inventory_2_rounded),
        l10n.diaryQuickEatSourceInventory,
      ),
      (
        DiaryQuickEatSource.manualSearch,
        const Icon(Icons.search_rounded),
        l10n.diaryQuickEatSourceManualSearch,
      ),
      (
        DiaryQuickEatSource.ai,
        const Icon(Icons.auto_awesome_rounded),
        l10n.diaryQuickEatSourceAi,
      ),
      (
        DiaryQuickEatSource.barcode,
        const Text(_barcodeGlyph),
        l10n.diaryQuickEatSourceBarcode,
      ),
    ];

    return Row(
      children: [
        for (final (index, (source, glyph, label)) in sources.indexed) ...[
          if (index > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _QuickEatButton(
              key: DiaryMealsSectionKeys.quickEatSource(source),
              glyph: glyph,
              label: label,
              expanded: expanded,
              onTap: () => onSelected(source),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickEatButton extends StatelessWidget {
  const new({
    required this.glyph,
    required this.label,
    required this.expanded,
    required this.onTap,
    super.key,
  });

  final Widget glyph;
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(
      expanded ? AppRadius.lg : AppRadius.md,
    );

    return Tooltip(
      message: label,
      excludeFromSemantics: expanded,
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: radius,
        child: AppInkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOutCubic,
            height: expanded ? _expandedHeight : _compactHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.xxs),
            // Scales the outgoing content down while the height shrinks.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedSwitcher(
                duration: _animationDuration,
                child: expanded
                    ? Column(
                        key: const ValueKey('expanded'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _sizedGlyph(context, 32),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      )
                    : KeyedSubtree(
                        key: const ValueKey('compact'),
                        child: _sizedGlyph(context, 20),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Sizes an icon or emoji glyph the same way.
  Widget _sizedGlyph(BuildContext context, double size) {
    final colors = Theme.of(context).colorScheme;
    return IconTheme.merge(
      data: IconThemeData(size: size, color: colors.onSurface),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.headlineMedium
            ?.copyWith(fontSize: size, color: colors.onSurface),
        child: glyph,
      ),
    );
  }
}
