import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_cook_list.dart';
import 'package:yamt/features/kochmodus/presentation/widgets/kochmodus_guide_step.dart';

/// "Kochen": the guide ("Kochhelfer") when [KochmodusView.showGuide], else
/// the list of lines; both with timers, voice and "Fertig · Portionieren".
class KochmodusCookStep extends StatelessWidget {
  /// Creates the step of [view] for the cooking of [target].
  const new({required this.target, required this.view, super.key});

  /// What the page cooks; actions go to its controller.
  final KochmodusTarget target;

  /// The cooking as it is now.
  final KochmodusView view;

  @override
  Widget build(BuildContext context) => view.showGuide
      ? KochmodusGuideStep(target: target, view: view)
      : KochmodusCookList(target: target, view: view);
}
