import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Maximum allowed line count for Dart files under lib/, as set in
/// architecture.md.
const maxFileLineLimit = 300;

void main() {
  group('Architecture - File Size Guard', () {
    test('non-test, non-generated Dart files must not exceed '
        '$maxFileLineLimit lines', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue, reason: 'lib/ directory must exist');

      final violations = <String>[];
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where(_isSubjectToLineCountCheck);

      for (final file in dartFiles) {
        final relativePath = file.path.replaceAll(r'\', '/');
        final lineCount = file.readAsLinesSync().length;

        if (lineCount > maxFileLineLimit &&
            !_legacyLargeFilesAllowlist.contains(relativePath)) {
          violations.add(
            '$relativePath: $lineCount lines (max $maxFileLineLimit)',
          );
        }
      }

      final failureMessage = StringBuffer()
        ..writeln(
          'The following new/unapproved files exceed the '
          '$maxFileLineLimit line limit:',
        )
        ..writeln(violations.join('\n'))
        ..writeln(
          '\nPer architecture.md, split files over $maxFileLineLimit lines '
          'by responsibility. NEVER add them to the allowlist.',
        );

      expect(violations, isEmpty, reason: failureMessage.toString());
    });
  });
}

bool _isSubjectToLineCountCheck(File file) {
  final path = file.path.replaceAll(r'\', '/');
  if (!path.endsWith('.dart')) return false;
  if (path.endsWith('.g.dart')) return false;
  if (path.endsWith('.freezed.dart')) return false;
  if (path.contains('/l10n/')) return false;
  if (path.endsWith('firebase_options.dart')) return false;
  return true;
}

/// Baseline allowlist for existing legacy files with > 300 lines.
/// When files are refactored, they are removed from this set so they
/// never regress (ratchet principle).
const _legacyLargeFilesAllowlist = <String>{
  'lib/features/activity/presentation/widgets/activity_weight_section/diary_compact_activity_weight_surface.dart',
  'lib/features/calories/application/daily_learned_tdee_resolver.dart',
  'lib/features/calories/debug/calorie_debug_dump_service.dart',
  'lib/features/calories/debug/calorie_debug_weekly_checkin_rows.dart',
  'lib/features/calories/domain/calorie_entry.dart',
  'lib/features/calories/domain/calorie_weekly_checkin.dart',
  'lib/features/calories/presentation/widgets/calorie_entry_editor_form_scaffold.dart',
  'lib/features/calories/presentation/widgets/calorie_goal_calculator_flow.dart',
  'lib/features/calories/presentation/widgets/calorie_learned_tdee_goal_sheet.dart',
  'lib/features/calories/provider/burn_week_run_controller.dart',
  'lib/features/calories/provider/calorie_entries_controller.dart',
  'lib/features/calories/provider/calorie_goal_calculator_form_state.dart',
  'lib/features/calories/provider/calorie_weekly_checkin_controller.dart',
  'lib/features/calories/provider/calorie_weekly_checkin_data_builder.dart',
  'lib/features/cooking_flow/application/cooking_flow_finalize_logic.dart',
  'lib/features/cooking_flow/application/cooking_flow_wizard_state.dart',
  'lib/features/cooking_flow/domain/cooking_flow_session.dart',
  'lib/features/cooking_flow/presentation/controllers/cooking_flow_intro_inventory_controller.dart',
  'lib/features/cooking_flow/presentation/controllers/cooking_flow_wizard_controller.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_finalize_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_intro_page_assignment.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_intro_page_widgets.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_inventory_conflict_panels.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_on_the_fly_adjustment_card.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_page_body.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_storage_container_controller.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_summary_page.dart',
  'lib/features/cooking_flow/presentation/cooking_flow_tare_utensil_picker.dart',
  'lib/features/diary/presentation/diary_inventory_food_picker.dart',
  'lib/features/diary/presentation/widgets/diary_weekly_checkin_section/diary_weekly_checkin_section.dart',
  'lib/features/health/data/health_connection_service_mobile.dart',
  'lib/features/inventory/application/ingredient_inventory_matcher.dart',
  'lib/features/inventory/application/prepared_meal_creation_workflows.dart',
  'lib/features/inventory/application/prepared_meal_editing_support.dart',
  'lib/features/inventory/application/prepared_meal_editing_workflows.dart',
  'lib/features/inventory/application/prepared_meal_inventory_math.dart',
  'lib/features/inventory/application/serving_suggestion_resolver.dart',
  'lib/features/inventory/data/firestore_global_food_serving_suggestion_repository.dart',
  'lib/features/inventory/data/global_food_item_store.dart',
  'lib/features/inventory/data/inventory_calorie_entry_commit_store.dart',
  'lib/features/inventory/data/prepared_meal_image_picker.dart',
  'lib/features/inventory/data/prepared_meal_recipe_html_parser.dart',
  'lib/features/inventory/domain/global_food_item.dart',
  'lib/features/inventory/domain/global_food_receipt_alias.dart',
  'lib/features/inventory/domain/inventory_item.dart',
  'lib/features/inventory/domain/prepared_meal.dart',
  'lib/features/inventory/presentation/controllers/inventory_items_controller.dart',
  'lib/features/inventory/presentation/controllers/prepared_meal_templates_controller.dart',
  'lib/features/inventory/presentation/controllers/prepared_meals_controller.dart',
  'lib/features/inventory/presentation/widgets/inventory_item_editor/inventory_receipt_item_editor_sheet.dart',
  'lib/features/inventory/presentation/widgets/inventory_list/inventory_item_row/inventory_item_row.dart',
  'lib/features/inventory/presentation/widgets/inventory_list/inventory_list.dart',
  'lib/features/inventory/presentation/widgets/inventory_list/inventory_list_sections.dart',
  'lib/features/inventory/presentation/widgets/inventory_list/inventory_prepared_meals_section.dart',
  'lib/features/inventory/presentation/widgets/inventory_list/inventory_unified_filter_sheet.dart',
  'lib/features/inventory/presentation/widgets/inventory_receipt_candidate_picker_sheet.dart',
  'lib/features/inventory/presentation/widgets/prepared_meals/prepared_meal_card.dart',
  'lib/features/inventory/presentation/widgets/prepared_meals/prepared_meal_card_actions.dart',
  'lib/features/inventory/presentation/widgets/prepared_meals/prepared_meal_creation_sheet.dart',
  'lib/features/inventory/presentation/widgets/prepared_meals/prepared_meal_edit_sheet.dart',
  'lib/features/kitchen_utensils/application/kitchen_utensil_mutation_service.dart',
  'lib/features/meal_templates/presentation/widgets/meal_template_recipe_template_sheet.dart',
  'lib/features/product_nutrition/data/nutrition_label_ocr_repository.dart',
  'lib/features/product_search_hub/data/product_ai_search_repository.dart',
  'lib/features/product_search_hub/presentation/controllers/manual_product_search_controller.dart',
  'lib/features/product_search_hub/presentation/controllers/manual_product_search_models.dart',
  'lib/features/product_search_hub/presentation/controllers/manual_product_search_state.dart',
  'lib/features/product_search_hub/presentation/widgets/manual_product_search_form/manual_product_search_form.dart',
  'lib/features/product_search_hub/presentation/widgets/manual_product_search_form/manual_product_search_shell.dart',
  'lib/features/product_search_hub/presentation/widgets/manual_product_search_form_details.dart',
  'lib/features/recipes/application/template_ingredient_parser.dart',
  'lib/features/settings/presentation/pages/account_page.dart',
  'lib/features/shared/widgets/auth_form_components.dart',
};
