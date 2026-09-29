// Legacy violations of the architecture rules, counted per file.
//
// When you fix a violation, lower its count or remove its entry in the
// same change. NEVER raise a count or add an entry: fix new violations
// instead.

/// Known violations per rule id and file path.
const architectureBaseline = <String, Map<String, int>>{
  'feature-order': {
    'lib/features/inventory/presentation/inventory_manual_product_search_launcher.dart':
        1,
    'lib/features/inventory/presentation/inventory_product_search_hub_completion_handler.dart':
        3,
  },
  'foreign-presentation': {
    'lib/features/ai_chef/presentation/widgets/ai_chef_dialog/ai_chef_dialog.dart':
        1,
    'lib/features/auth/presentation/welcome_page.dart': 1,
    'lib/features/auth/presentation/widgets/auth_action_button/auth_action_button.dart':
        1,
    'lib/features/auth/presentation/widgets/auth_card/auth_card.dart': 1,
    'lib/features/auth/presentation/widgets/auth_divider/auth_divider.dart': 1,
    'lib/features/auth/presentation/widgets/auth_ghost_text_button/auth_ghost_text_button.dart':
        1,
    'lib/features/auth/presentation/widgets/auth_header/auth_header.dart': 1,
    'lib/features/auth/presentation/widgets/auth_layout_metrics/auth_layout_metrics.dart':
        1,
    'lib/features/auth/presentation/widgets/login_form/login_form.dart': 1,
    'lib/features/auth/presentation/widgets/register_form/register_form.dart':
        1,
    'lib/features/auth/presentation/widgets/welcome_page_desktop_layout/welcome_page_desktop_layout.dart':
        1,
    'lib/features/auth/presentation/widgets/welcome_page_editorial_aside/welcome_page_editorial_aside.dart':
        1,
    'lib/features/cooking_flow/presentation/controllers/cooking_flow_controller.dart':
        1,
    'lib/features/cooking_flow/presentation/controllers/cooking_flow_shopping_controller.dart':
        1,
    'lib/features/cooking_flow/presentation/cooking_flow_cooking_page.dart': 1,
    'lib/features/cooking_flow/presentation/cooking_flow_intro_page.dart': 1,
    'lib/features/cooking_flow/presentation/cooking_flow_page.dart': 2,
    'lib/features/cooking_flow/presentation/cooking_flow_summary_ingredient_source_flow.dart':
        1,
    'lib/features/home/widgets/inventory_action_sheet_flow.dart': 2,
    'lib/features/home_widget/presentation/controllers/home_widget_sync_controller.dart':
        1,
    'lib/features/inventory/presentation/controllers/inventory_items_controller.dart':
        1,
    'lib/features/inventory/presentation/inventory_shopping_list_page.dart': 1,
    'lib/features/meal_templates/presentation/meal_template_import_review_page.dart':
        1,
    'lib/features/meal_templates/presentation/widgets/meal_templates_page/meal_templates_page.dart':
        1,
    'lib/features/onboarding/presentation/models/intro_input_page_args.dart': 1,
    'lib/features/onboarding/presentation/widgets/intro/calorie_intro_flow.dart':
        1,
    'lib/features/onboarding/presentation/widgets/intro/calorie_intro_pages.dart':
        1,
    'lib/features/product_search_hub/presentation/widgets/product_search_barcode_candidate_picker_sheet.dart':
        1,
    'lib/features/product_search_hub/presentation/widgets/product_search_hub_search_results/product_search_hub_search_results.dart':
        1,
    'lib/features/settings/presentation/controllers/account_controller.dart': 1,
    'lib/features/settings/presentation/pages/account_page.dart': 1,
    'lib/features/settings/presentation/widgets/link_email_password_dialog/link_email_password_dialog.dart':
        1,
  },
  'feature-folders': {
    'lib/features/home/home_page.dart': 1,
    'lib/features/home/widgets/inventory_action_sheet_flow.dart': 1,
    'lib/features/onboarding/provider/calorie_goal_onboarding_completed_provider.dart':
        1,
    'lib/features/shared/widgets/auth_form_components.dart': 1,
    'lib/features/shared/widgets/credential_form_ui_constants.dart': 1,
    'lib/features/shared/widgets/email_password_credentials_form.dart': 1,
  },
  'presentation-folders': {
    'lib/features/auth/presentation/auth_error_message_mapper.dart': 1,
    'lib/features/diary/presentation/diary_calendar_controller.dart': 1,
    'lib/features/diary/presentation/diary_home_widget_summary_provider.dart':
        1,
    'lib/features/diary/presentation/diary_inventory_food_picker.dart': 1,
    'lib/features/diary/presentation/diary_product_search_hub_completion_handler.dart':
        1,
    'lib/features/diary/presentation/diary_weekly_checkin_dialog_scheduler.dart':
        1,
    'lib/features/diary/presentation/diary_weekly_checkin_messages.dart': 1,
    'lib/features/diary/presentation/diary_weekly_checkin_snackbars.dart': 1,
    'lib/features/household/presentation/household_error_message.dart': 1,
    'lib/features/inventory/presentation/formatters/inventory_nutrition_format.dart':
        1,
    'lib/features/inventory/presentation/inventory_amount_unit_l10n.dart': 1,
    'lib/features/inventory/presentation/inventory_calorie_stock_adjuster.dart':
        1,
    'lib/features/inventory/presentation/inventory_controller_access.dart': 1,
    'lib/features/inventory/presentation/inventory_manual_product_eat_coordinator.dart':
        1,
    'lib/features/inventory/presentation/inventory_manual_product_search_launcher.dart':
        1,
    'lib/features/inventory/presentation/inventory_prepared_meal_edit_coordinator.dart':
        1,
    'lib/features/inventory/presentation/inventory_product_search_hub_completion_handler.dart':
        1,
    'lib/features/inventory/presentation/utils/off_product_nutrition_grade_extension.dart':
        1,
    'lib/features/onboarding/presentation/calorie_goal_onboarding_keys.dart': 1,
    'lib/features/product_search_hub/presentation/product_search_hub_barcode_direct_result.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_barcode_scanner.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_navigation.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_quick_eat_config.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_recent_item_key.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_search_config.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_search_context.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_search_coordinator.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_search_entry_launcher.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_search_lookup.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_selection_state.dart':
        1,
    'lib/features/scanner/presentation/flow/receipt_camera_supported.dart': 1,
    'lib/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart':
        1,
    'lib/features/scanner/presentation/shared/pending_shared_receipt_paths.dart':
        1,
    'lib/features/scanner/presentation/shared/shared_receipt_listener.dart': 1,
    'lib/features/scanner/presentation/shared/shared_receipt_service.dart': 1,
    'lib/features/settings/presentation/pages/account_page.dart': 1,
    'lib/features/settings/presentation/pages/settings_page.dart': 1,
    'lib/features/settings/presentation/pages/settings_page_keys.dart': 1,
  },
  'file-roles': {
    'lib/features/calories/application/burn_week_live_mutation_coordinator.dart':
        1,
    'lib/features/calories/application/burn_week_live_overview_logic.dart': 1,
    'lib/features/calories/application/burn_week_live_window_logic.dart': 1,
    'lib/features/calories/application/calorie_entry_inventory_restore_coordinator.dart':
        1,
    'lib/features/calories/application/calorie_inventory_entry_save_handler.dart':
        1,
    'lib/features/calories/data/calorie_entry_document_codec.dart': 1,
    'lib/features/calories/data/calorie_log_repository_contract.dart': 1,
    'lib/features/calories/data/calorie_product_cache_document_codec.dart': 1,
    'lib/features/calories/data/calorie_product_cache_repository_contract.dart':
        1,
    'lib/features/calories/domain/burn_week_mock_logic.dart': 1,
    'lib/features/calories/domain/calorie_goal_transition_helpers.dart': 1,
    'lib/features/calories/presentation/widgets/calorie_entry_editor_flow_handler.dart':
        1,
    'lib/features/cooking_flow/application/cooking_flow_amount_utils.dart': 1,
    'lib/features/cooking_flow/application/cooking_flow_finalize_logic.dart': 1,
    'lib/features/cooking_flow/data/cooking_flow_session_local_store.dart': 1,
    'lib/features/diary/presentation/diary_product_search_hub_completion_handler.dart':
        1,
    'lib/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart':
        1,
    'lib/features/home_widget/application/home_widget_action_uri_codec.dart': 1,
    'lib/features/home_widget/data/home_widget_plugin_bridge.dart': 1,
    'lib/features/household/application/household_access_recovery_utils.dart':
        1,
    'lib/features/inventory/application/inventory_manual_product_eat_flow_contract.dart':
        1,
    'lib/features/inventory/application/inventory_pending_consumption_store.dart':
        1,
    'lib/features/inventory/application/prepared_meal_calorie_log_bridge.dart':
        1,
    'lib/features/inventory/application/prepared_meal_consumption_workflows.dart':
        1,
    'lib/features/inventory/application/prepared_meal_creation_support.dart': 1,
    'lib/features/inventory/application/prepared_meal_creation_workflows.dart':
        1,
    'lib/features/inventory/application/prepared_meal_editing_support.dart': 1,
    'lib/features/inventory/application/prepared_meal_editing_workflows.dart':
        1,
    'lib/features/inventory/application/prepared_meal_mutation_workflows.dart':
        1,
    'lib/features/inventory/application/prepared_meal_pending_ingredient_support.dart':
        1,
    'lib/features/inventory/application/prepared_meal_template_creation_support.dart':
        1,
    'lib/features/inventory/application/recipe_ingredient_assignment_support.dart':
        1,
    'lib/features/inventory/data/firestore_inventory_calorie_entry_commit_store.dart':
        1,
    'lib/features/inventory/data/global_barcode_candidate_repository_contract.dart':
        1,
    'lib/features/inventory/data/global_food_item_repository_contract.dart': 1,
    'lib/features/inventory/data/global_food_item_store.dart': 1,
    'lib/features/inventory/data/global_food_receipt_alias_repository_contract.dart':
        1,
    'lib/features/inventory/data/global_food_receipt_alias_store.dart': 1,
    'lib/features/inventory/data/inventory_calorie_entry_commit_store.dart': 1,
    'lib/features/inventory/data/inventory_calorie_entry_commit_store_contract.dart':
        1,
    'lib/features/inventory/data/inventory_item_repository_contract.dart': 1,
    'lib/features/inventory/data/inventory_item_store.dart': 1,
    'lib/features/inventory/data/prepared_meal_calorie_entry_commit_store.dart':
        1,
    'lib/features/inventory/data/prepared_meal_repository_contract.dart': 1,
    'lib/features/inventory/data/prepared_meal_store.dart': 1,
    'lib/features/inventory/data/prepared_meal_template_repository_contract.dart':
        1,
    'lib/features/inventory/data/prepared_meal_template_store.dart': 1,
    'lib/features/inventory/domain/global_food_serving_suggestion_repository_contract.dart':
        1,
    'lib/features/inventory/domain/inventory_parsing_utils.dart': 1,
    'lib/features/inventory/presentation/inventory_manual_product_eat_coordinator.dart':
        1,
    'lib/features/inventory/presentation/inventory_prepared_meal_edit_coordinator.dart':
        1,
    'lib/features/inventory/presentation/inventory_product_search_hub_completion_handler.dart':
        1,
    'lib/features/kitchen_utensils/data/kitchen_utensil_image_store.dart': 1,
    'lib/features/kitchen_utensils/data/kitchen_utensil_repository_contract.dart':
        1,
    'lib/features/kitchen_utensils/data/kitchen_utensil_store.dart': 1,
    'lib/features/product_search_hub/data/composite_product_search_adapter.dart':
        1,
    'lib/features/product_search_hub/domain/manual_product_search_value_utils.dart':
        1,
    'lib/features/product_search_hub/domain/product_search_hub_completion_handler.dart':
        1,
    'lib/features/product_search_hub/presentation/product_search_hub_search_coordinator.dart':
        1,
    'lib/features/product_search_hub/presentation/widgets/manual_product_search_editor_page/manual_product_search_editor_barcode_coordinator.dart':
        1,
    'lib/features/product_search_hub/presentation/widgets/manual_product_search_editor_page/manual_product_search_editor_support.dart':
        1,
    'lib/features/scanner/presentation/flow/receipt_scan_flow_coordinator.dart':
        1,
  },
  'flow-placement': {
    'lib/features/calories/application/calorie_entry_amount_edit_flow.dart': 1,
    'lib/features/calories/application/calorie_entry_delete_flow.dart': 1,
    'lib/features/calories/application/calorie_goal_seed_weight_flow.dart': 1,
    'lib/features/home/widgets/inventory_action_sheet_flow.dart': 1,
    'lib/features/inventory/application/inventory_backed_calorie_entry_save_flow.dart':
        1,
    'lib/features/inventory/application/inventory_calorie_bridge_flow.dart': 1,
    'lib/features/onboarding/application/calorie_goal_onboarding_finish_flow.dart':
        1,
  },
  'clock': {
    'lib/core/domain/local_day_window.dart': 1,
    'lib/features/calories/application/burn_week_live_sync_provider.dart': 2,
    'lib/features/calories/application/calorie_weekly_checkin_snapshot_invalidator.dart':
        1,
    'lib/features/calories/domain/calorie_entry.dart': 5,
    'lib/features/calories/domain/calorie_goal_settings_queries.dart': 1,
    'lib/features/calories/domain/tdee_cycle_resolver.dart': 1,
    'lib/features/cooking_flow/application/cooking_flow_finalize_logic.dart': 2,
    'lib/features/inventory/application/inventory_calorie_bridge_flow.dart': 3,
    'lib/features/inventory/application/inventory_shopping_suggestions.dart': 1,
    'lib/features/inventory/application/off_product_candidate_source.dart': 1,
    'lib/features/inventory/domain/global_barcode_candidate.dart': 1,
    'lib/features/inventory/domain/global_food_item.dart': 2,
    'lib/features/inventory/domain/global_food_receipt_alias.dart': 2,
    'lib/features/inventory/domain/global_food_serving_suggestion.dart': 1,
    'lib/features/inventory/domain/inventory_activity_event.dart': 2,
    'lib/features/inventory/domain/inventory_discard_event.dart': 2,
    'lib/features/inventory/domain/inventory_item.dart': 1,
    'lib/features/inventory/domain/prepared_meal.dart': 1,
    'lib/features/inventory/presentation/controllers/inventory_items_controller.dart':
        2,
    'lib/features/inventory/presentation/controllers/prepared_meal_templates_controller.dart':
        4,
    'lib/features/kitchen_utensils/application/kitchen_utensil_mutation_service.dart':
        2,
    'lib/features/kitchen_utensils/domain/kitchen_utensil.dart': 1,
    'lib/features/shoppinglist/presentation/controllers/shopping_list_controller.dart':
        3,
  },
  'sdk-instance': {
    'lib/features/auth/data/auth_service.dart': 1,
    'lib/features/auth/data/google_sign_in_provider.dart': 1,
    'lib/features/inventory/data/global_food_item_repository.dart': 1,
    'lib/features/inventory/data/global_food_receipt_alias_repository.dart': 1,
  },
  'theme-values': {
    'lib/features/ai_chef/presentation/widgets/ai_chef_dialog/ai_chef_action_buttons_row.dart':
        1,
    'lib/features/ai_chef/presentation/widgets/ai_chef_dialog/ai_chef_loading_view.dart':
        1,
    'lib/features/ai_chef/presentation/widgets/ai_chef_dialog/ai_chef_recipe_ingredients_card.dart':
        5,
    'lib/features/ai_chef/presentation/widgets/ai_chef_dialog/ai_chef_recipe_stats_row.dart':
        6,
    'lib/features/calories/presentation/widgets/calorie_goal_training_days_card.dart':
        2,
    'lib/features/calories/presentation/widgets/tdee_analytics/tdee_goal_selector.dart':
        1,
    'lib/features/calories/presentation/widgets/tdee_analytics/tdee_weight_chart_builder.dart':
        2,
    'lib/features/diary/presentation/widgets/diary_burn_week_card/diary_balance_progress_helpers.dart':
        1,
    'lib/features/inventory/presentation/widgets/inventory_action_picker_sheet.dart':
        1,
    'lib/features/meal_templates/presentation/widgets/meal_template_recipe_template_sheet.dart':
        3,
    'lib/features/meal_templates/presentation/widgets/prepared_meal_template_card/prepared_meal_template_card.dart':
        2,
    'lib/features/product_search_hub/presentation/widgets/product_search_barcode_scanner_page/product_search_barcode_scanner_resolving_indicator.dart':
        1,
    'lib/features/scanner/presentation/widgets/product_nutrition_summary.dart':
        4,
    'lib/features/scanner/presentation/widgets/receipt_item_candidates_list.dart':
        3,
    'lib/features/scanner/presentation/widgets/receipt_item_edit_sheet.dart': 4,
    'lib/features/scanner/presentation/widgets/receipt_item_leading_avatar.dart':
        2,
    'lib/features/scanner/presentation/widgets/receipt_item_matched_product_card.dart':
        3,
    'lib/features/scanner/presentation/widgets/receipt_review_badges_row.dart':
        10,
    'lib/features/scanner/presentation/widgets/receipt_review_bottom_bar.dart':
        3,
    'lib/features/scanner/presentation/widgets/receipt_review_header.dart': 6,
    'lib/features/scanner/presentation/widgets/receipt_review_item_card.dart':
        12,
    'lib/features/settings/presentation/widgets/link_email_password_dialog/link_email_password_dialog.dart':
        1,
    'lib/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_multiplier_card.dart':
        3,
    'lib/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_preview_card.dart':
        6,
    'lib/features/shoppinglist/presentation/widgets/shopping_list_item_tile.dart':
        2,
    'lib/features/shoppinglist/presentation/widgets/shopping_quick_add_dialog.dart':
        1,
  },
  'ignore-comment': {
    'lib/core/theme/metric_accent_colors.dart': 1,
    'lib/core/widgets/app_dropdown_button.dart': 1,
    'lib/core/widgets/app_ink_well.dart': 1,
    'lib/core/widgets/app_selection_list_tiles.dart': 1,
    'lib/core/widgets/app_switch_list_tile.dart': 1,
    'lib/features/calories/application/calorie_weekly_checkin_build_models.dart':
        1,
    'lib/features/calories/application/calorie_weekly_checkin_health_loader.dart':
        1,
    'lib/features/inventory/presentation/controllers/inventory_items_controller.dart':
        1,
    'lib/features/inventory/presentation/controllers/prepared_meal_templates_controller.dart':
        1,
    'lib/features/inventory/presentation/controllers/prepared_meals_controller.dart':
        1,
    'lib/features/kitchen_utensils/presentation/controllers/kitchen_utensils_controller.dart':
        1,
    'lib/features/shared/widgets/auth_form_components.dart': 1,
  },
  'route-extra-cast': {'lib/core/router/app_route_definitions.dart': 1},
  'bare-keep-alive': {
    'lib/features/calories/application/burn_week_live_sync_provider.dart': 1,
    'lib/features/calories/application/calorie_entry_amount_edit_flow.dart': 2,
    'lib/features/calories/application/calorie_entry_delete_flow.dart': 1,
    'lib/features/calories/application/calorie_inventory_entry_save_handler.dart':
        2,
    'lib/features/calories/presentation/controllers/calorie_entry_editor_controller.dart':
        1,
    'lib/features/inventory/application/inventory_backed_calorie_entry_save_flow.dart':
        1,
    'lib/features/inventory/application/inventory_calorie_entry_post_persist_hook.dart':
        1,
    'lib/features/inventory/presentation/inventory_calorie_entry_delete_flow.dart':
        1,
    'lib/features/inventory/presentation/inventory_calorie_stock_adjuster.dart':
        1,
  },
  'export': {
    'lib/core/widgets/text_voice_search_bar/text_voice_search_bar.dart': 1,
    'lib/features/diary/presentation/controllers/diary_day_dashboard_controller.dart':
        1,
    'lib/features/inventory/data/global_barcode_candidate_repository.dart': 1,
    'lib/features/inventory/data/global_food_item_repository.dart': 3,
    'lib/features/inventory/data/global_food_receipt_alias_repository.dart': 3,
    'lib/features/inventory/data/global_food_serving_suggestion_repository.dart':
        1,
    'lib/features/inventory/data/inventory_calorie_entry_commit_store.dart': 4,
    'lib/features/inventory/data/inventory_item_repository.dart': 4,
    'lib/features/inventory/data/off_product_search_repository.dart': 1,
    'lib/features/inventory/data/prepared_meal_repository.dart': 3,
    'lib/features/inventory/data/prepared_meal_template_repository.dart': 3,
    'lib/features/inventory/domain/inventory_item.dart': 1,
    'lib/features/inventory/presentation/controllers/prepared_meals_controller.dart':
        1,
  },
  'domain-imports': {
    'lib/features/calories/domain/calorie_goal_calculator.dart': 1,
    'lib/features/calories/domain/calorie_weekly_checkin.dart': 1,
    'lib/features/calories/domain/daily_nutrition_target.dart': 1,
    'lib/features/calories/domain/macro_budget_calculator.dart': 1,
    'lib/features/calories/domain/macro_carryover_calculator.dart': 1,
    'lib/features/calories/domain/macro_goal_settings.dart': 1,
    'lib/features/diary/domain/diary_macro_targets.dart': 1,
    'lib/features/inventory/domain/inventory_parsing_utils.dart': 1,
    'lib/features/inventory/domain/prepared_meal.dart': 1,
    'lib/features/product_search_hub/domain/product_search_hub_completion_handler.dart':
        1,
    'lib/features/scanner/domain/contracts/receipt_manual_product_picker.dart':
        1,
  },
  'session-interface': {
    'lib/features/inventory/data/inventory_user_session.dart': 1,
  },
};
