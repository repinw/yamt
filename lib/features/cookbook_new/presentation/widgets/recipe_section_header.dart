import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cookbook_new/presentation/widgets/cookbook_section_title.dart';

/// A section title of the recipe page.
class RecipeSectionHeader extends StatelessWidget {
  /// Creates the header [title].
  const new({required this.title, super.key});

  /// Name of the section.
  final String title;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CookbookSectionTitle(title: title),
      ),
    ),
  );
}
