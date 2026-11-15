import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_assign_head.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_entered_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_group_title.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_card.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ingredient_row.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_nutrition_label.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_ready_card.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Was hast du da?" one line at a time: the progress, the card of the line
/// it asks now, and under it every line in "Alle Zutaten". The card asks the
/// first line still to answer (`KochmodusView.toAnswer`); after an answer the
/// next one takes it, unless the answered line still needs one (too little
/// is there), which stays. A tap on a row puts that line on the card until
/// the cook answers it or closes the card. Once nothing is left to answer
/// the card is `KochmodusReadyCard`, and with "Alles bereit" the food label
/// of one portion stands under it, headed "Portion · geschätzt" while a
/// line's weight is only estimated (`KochmodusView.estimated`). Once "Hab
/// ich" brought a food that the line takes something of, or a new food it
/// cannot take from yet, a line under the card says what went in
/// (`KochmodusEnteredCard`, `KochmodusLineView.confirms`) until the next
/// answer.
class KochmodusAssignStep extends StatefulWidget {
  /// Creates the step of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// Key of the card.
  static const cardKey = ValueKey<String>('kochmodus-assign-card');

  /// Key of the food label of one portion under "Alles bereit".
  static const labelKey = ValueKey<String>('kochmodus-assign-label');

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  @override
  State<KochmodusAssignStep> createState() => _KochmodusAssignStepState();
}

class _KochmodusAssignStepState extends State<KochmodusAssignStep> {
  final _scroll = ScrollController();

  // The line the cook tapped in the list.
  String? _picked;

  // The line answered last; it keeps the card while it still needs an answer.
  String? _answered;

  // The food the last answer brought.
  KochmodusNewFood? _food;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  KochmodusLineView? get _onCard {
    final view = widget.view;
    KochmodusLineView? find(List<KochmodusLineView> lines, String? id) =>
        id == null ? null : lines.firstWhereOrNull((line) => line.id == id);
    return find(view.lines, _picked) ??
        find(view.toAnswer, _answered) ??
        view.toAnswer.firstOrNull;
  }

  void _pick(String lineId) {
    setState(() => _picked = lineId);
    if (_scroll.hasClients && _scroll.offset > 0) _scroll.jumpTo(0);
  }

  void _onAnswered(String lineId, KochmodusNewFood? food) {
    if (!mounted) return;
    setState(() {
      _picked = null;
      _answered = lineId;
      _food = food;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final view = widget.view;
    final onCard = _onCard;
    final food = _food;
    // Only with "Alles bereit": nothing to buy, everything settled.
    final label = view.portionLabel;
    final foodLine = food == null
        ? null
        : view.lines.firstWhereOrNull((line) => line.id == food.lineId);
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            0,
          ),
          sliver: SliverList.list(
            children: [
              KochmodusAssignHead(view: view, onCard: onCard?.id),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                key: KochmodusAssignStep.cardKey,
                decoration: BoxDecoration(
                  color: FoodLabelColors.of(context).card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: onCard == null
                      ? KochmodusReadyCard(target: widget.target, view: view)
                      : KochmodusIngredientCard(
                          key: ValueKey<String>(onCard.id),
                          target: widget.target,
                          view: view,
                          line: onCard,
                          onAnswered: (food) => _onAnswered(onCard.id, food),
                          onClose: _picked == null
                              ? null
                              : () => setState(() => _picked = null),
                        ),
                ),
              ),
              // Under the card, so the answers stay where the thumb is when
              // the line comes and goes.
              // Only while the line takes something of the food, or holds a
              // new one it cannot take from yet.
              if (food != null &&
                  foodLine != null &&
                  foodLine.confirms(food)) ...[
                const SizedBox(height: AppSpacing.md),
                KochmodusEnteredCard(
                  target: widget.target,
                  view: view,
                  line: foodLine,
                  food: food,
                  onShowLine: () => _pick(food.lineId),
                ),
              ],
              if (onCard == null && label != null) ...[
                const SizedBox(height: AppSpacing.xl),
                KochmodusNutritionLabel(
                  key: KochmodusAssignStep.labelKey,
                  eaten: label,
                  eatenHeader: view.estimated.isEmpty
                      ? l10n.kochmodusNutritionPer('portion')
                      : l10n.kochmodusNutritionPortionEstimated,
                ),
              ],
              KochmodusGroupTitle(title: l10n.kochmodusAssignAll),
            ],
          ),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            sliver: SliverList.builder(
              itemCount: view.lines.length,
              itemBuilder: (context, index) {
                final line = view.lines[index];
                return KochmodusIngredientRow(
                  line: line,
                  onCard: line.id == onCard?.id,
                  onTap: () => _pick(line.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
