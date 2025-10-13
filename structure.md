Возмоно не актуально

```

Hoplixi — Быстрый онбординг для AI
│   app.dart
│   global_key.dart
│   main.dart
│
├───app
│   ├───app_preferences
│   │       app_preferences.dart
│   │       index.dart
│   │       keys.dart
│   │       README.md
│   │
│   ├───constants
│   │       main_constants.dart
│   │       responsive_constants.dart
│   │
│   ├───errors
│   │       db_errors.dart
│   │       db_errors.freezed.dart
│   │       error.dart
│   │       error.freezed.dart
│   │       error_handler.dart
│   │       ERROR_HANDLING_GUIDE.md
│   │       index.dart
│   │
│   ├───router
│   │       router_provider.dart
│   │       router_refresh_provider.dart
│   │       routes.dart
│   │       routes_path.dart
│   │
│   └───theme
│           button_themes.dart
│           colors.dart
│           component_themes.dart
│           constants.dart
│           index.dart
│           theme.dart
│           theme_provider.dart
│           theme_switcher.dart
│
├───core
│   │   app_paths.dart
│   │   index.dart
│   │
│   ├───flutter_secure_storage
│   │       flutter_secure_storage_impl.dart
│   │
│   ├───lib
│   │   ├───box_db_old
│   │   │       box_db.dart
│   │   │       box_key_manager.dart
│   │   │       crypto_box.dart
│   │   │       errors.dart
│   │   │       example.dart
│   │   │       simple_box.dart
│   │   │       simple_box_manager.dart
│   │   │       simple_box_utils.dart
│   │   │       types.dart
│   │   │       utils.dart
│   │   │
│   │   ├───box_db_new
│   │   │   │   box_db.dart
│   │   │   │   box_manager.dart
│   │   │   │   encryption_service.dart
│   │   │   │   index.dart
│   │   │   │   index_manager.dart
│   │   │   │   QUICKSTART.md
│   │   │   │   README.md
│   │   │   │   secure_storage.dart
│   │   │   │   storage_manager.dart
│   │   │   │
│   │   │   ├───docs
│   │   │   │       API.md
│   │   │   │       ARCHITECTURE.md
│   │   │   │       BOX_MANAGER.md
│   │   │   │       COMPACTION_FIX.md
│   │   │   │       EXAMPLES.md
│   │   │   │       EXPORT_IMPORT_GUIDE.md
│   │   │   │       NEW_COMPACTION.md
│   │   │   │       NEW_COMPACTION_MECHANISM.md
│   │   │   │       SUMMARY.md
│   │   │   │       TIME_QUERIES_REPORT.md
│   │   │   │
│   │   │   └───models
│   │   │           user.dart
│   │   │           user.freezed.dart
│   │   │           user.g.dart
│   │   │
│   │   ├───dropbox_api
│   │   │   │   dropbox_api.dart
│   │   │   │
│   │   │   └───src
│   │   │       │   dropbox_rest_api.dart
│   │   │       │   interface.dart
│   │   │       │
│   │   │       └───models
│   │   │               dropbox_account.dart
│   │   │               dropbox_file.dart
│   │   │               dropbox_folder.dart
│   │   │               dropbox_folder_contents.dart
│   │   │               models.dart
│   │   │
│   │   ├───google_drive_api
│   │   │   │   google_drive_api.dart
│   │   │   │
│   │   │   └───src
│   │   │           drive_list_response.dart
│   │   │           file_list_response.dart
│   │   │           gd_drive.dart
│   │   │           gd_file.dart
│   │   │           google_drive.dart
│   │   │           interface.dart
│   │   │
│   │   ├───oauth2restclient
│   │   │   │   oauth2restclient.dart
│   │   │   │
│   │   │   └───src
│   │   │       │   oauth2_account.dart
│   │   │       │   oauth2_cancel_token.dart
│   │   │       │
│   │   │       ├───exception
│   │   │       │       oauth2_exception.dart
│   │   │       │       oauth2_exception_type.dart
│   │   │       │
│   │   │       ├───provider
│   │   │       │       dropbox.dart
│   │   │       │       google.dart
│   │   │       │       microsoft.dart
│   │   │       │       oauth2_provider.dart
│   │   │       │       pkce.dart
│   │   │       │       yandex.dart
│   │   │       │
│   │   │       ├───rest_client
│   │   │       │       http_method.dart
│   │   │       │       http_oauth2_rest_client.dart
│   │   │       │       oauth2_multipart.dart
│   │   │       │       oauth2_rest_body.dart
│   │   │       │       oauth2_rest_client.dart
│   │   │       │       oauth2_rest_response.dart
│   │   │       │
│   │   │       └───token
│   │   │               oauth2_token.dart
│   │   │               oauth2_token_storage.dart
│   │   │
│   │   ├───onedrive_api
│   │   │   │   onedrive_rest_api.dart
│   │   │   │
│   │   │   └───src
│   │   │       │   interface.dart
│   │   │       │   onedrive_api.dart
│   │   │       │
│   │   │       └───models
│   │   │               models.dart
│   │   │               onedrive_drive.dart
│   │   │               onedrive_drive_item.dart
│   │   │               onedrive_drive_items.dart
│   │   │               onedrive_user.dart
│   │   │
│   │   ├───sodium_file_encryptor
│   │   │       aead_file_encryptor.dart
│   │   │       index.dart
│   │   │
│   │   └───yandex_drive_api
│   │       │   yandex_drive_api.dart
│   │       │
│   │       └───src
│   ├───logger
│   │       app_logger.dart
│   │       file_manager.dart
│   │       log_buffer.dart
│   │       models.dart
│   │       riverpod_observer.dart
│   │       route_observer.dart
│   │
│   ├───providers
│   │       app_close_provider.dart
│   │       app_lifecycle_provider.dart
│   │       biometric_auto_open_provider.dart
│   │       biometric_provider.dart
│   │       box_db_provider.dart
│   │       file_encryptor_provider.dart
│   │       FILE_ENCRYPTOR_README.md
│   │       file_encryptor_usage_example.md
│   │       notification_providers.dart
│   │       secure_storage_provider.dart
│   │       sodium_provider.dart
│   │
│   ├───services
│   │       biometric_service.dart
│   │       notification_helpers.dart
│   │       notification_service.dart
│   │
│   └───utils
│       │   otp_extractor.dart
│       │   parse_hex_color.dart
│       │   toastification.dart
│       │   window_manager.dart
│       │
│       ├───file_crypto
│       │       aead_file_encryptor.dart
│       │       crypto_keys.dart
│       │       file_encryptor.dart
│       │       index.dart
│       │
│       ├───responsive_ui
│       ├───scaffold_messenger_manager
│       │   │   example_usage.dart
│       │   │   index.dart
│       │   │   README.md
│       │   │   scaffold_messenger_manager.dart
│       │   │
│       │   ├───builders
│       │   │       banner_builder.dart
│       │   │       snack_bar_builder.dart
│       │   │
│       │   ├───docs
│       │   │       pre_initialization_queue.md
│       │   │
│       │   ├───examples
│       │   │       pre_initialization_example.dart
│       │   │
│       │   ├───extensions
│       │   │       messenger_extensions.dart
│       │   │
│       │   ├───models
│       │   │       banner_animation_config.dart
│       │   │       banner_data.dart
│       │   │       snack_bar_animation_config.dart
│       │   │       snack_bar_data.dart
│       │   │       snack_bar_type.dart
│       │   │
│       │   ├───queue
│       │   │       snack_bar_queue_manager.dart
│       │   │
│       │   ├───themes
│       │   │       banner_theme_provider.dart
│       │   │       default_banner_theme_provider.dart
│       │   │       default_snack_bar_theme_provider.dart
│       │   │       snack_bar_theme_provider.dart
│       │   │
│       │   └───widgets
│       │           animated_snack_bar.dart
│       │           rounded_material_banner.dart
│       │
│       └───toast
│               toast.dart
│               toast_item.dart
│               toast_manager.dart
│               ui.dart
│
├───features
│   ├───cloud_sync
│   │   │   README.md
│   │   │   ROUTER_INTEGRATION.md
│   │   │   SUMMARY.md
│   │   │   SYNC_README.md
│   │   │
│   │   ├───examples
│   │   │       sync_example.dart
│   │   │
│   │   ├───models
│   │   │       credential_app.dart
│   │   │       credential_app.freezed.dart
│   │   │       credential_app.g.dart
│   │   │       models.dart
│   │   │       sync_metadata.dart
│   │   │       sync_metadata.freezed.dart
│   │   │       sync_metadata.g.dart
│   │   │       token_oauth.dart
│   │   │       token_oauth.freezed.dart
│   │   │       token_oauth.g.dart
│   │   │
│   │   ├───providers
│   │   │       credential_provider.dart
│   │   │       dropbox_provider.dart
│   │   │       oauth2_account_provider.dart
│   │   │       token_provider.dart
│   │   │       token_services_provider.dart
│   │   │
│   │   ├───screens
│   │   │       auth_manager_screen.dart
│   │   │       manage_credential_screen.dart
│   │   │       token_list_screen.dart
│   │   │
│   │   ├───services
│   │   │       credential_service.dart
│   │   │       dropbox_service.dart
│   │   │       oauth2_account_service.dart
│   │   │       services.dart
│   │   │       sync_metadata_service.dart
│   │   │       token_services.dart
│   │   │
│   │   └───widgets
│   │           auth_modal.dart
│   │           credential_card.dart
│   │           credential_form_dialog.dart
│   │           credential_picker.dart
│   │           README_AUTH_MODAL.md
│   │
│   ├───demo
│   │   │   notification_demo_screen.dart
│   │   │
│   │   └───notification_demo
│   │           notification_demo_screen.dart
│   │
│   ├───global
│   │   └───screens
│   │           error_screen.dart
│   │           image_crop_example.dart
│   │           image_crop_screen.dart
│   │           README.md
│   │           splash_screen.dart
│   │
│   ├───home
│   │   │   home.dart
│   │   │   home_controller.dart
│   │   │
│   │   └───widgets
│   │           action_button.dart
│   │           database_password_dialog.dart
│   │           index.dart
│   │           recent_database_card.dart
│   │
│   ├───localsend
│   │   │   log.txt
│   │   │
│   │   ├───models
│   │   │       connection_mode.dart
│   │   │       localsend_device_info.dart
│   │   │       localsend_device_info.freezed.dart
│   │   │       localsend_device_info.g.dart
│   │   │       webrtc_error.dart
│   │   │       webrtc_state.dart
│   │   │       webrtc_state.freezed.dart
│   │   │
│   │   ├───providers
│   │   │       discovery_provider.dart
│   │   │       http_signaling_provider.dart
│   │   │       message_history_provider.dart
│   │   │       webrtc_provider.dart
│   │   │
│   │   ├───screens
│   │   │       discovery_screen.dart
│   │   │       transceive_screen.dart
│   │   │
│   │   ├───services
│   │   │       http_signaling_service.dart
│   │   │       webrtc_service.dart
│   │   │
│   │   └───widgets
│   │           connection_mode_dialog.dart
│   │
│   ├───password_manager
│   │   ├───before_opening
│   │   │   ├───create_store
│   │   │   │   │   create_store.dart
│   │   │   │   │   create_store_control.dart
│   │   │   │   │   README.md
│   │   │   │   │
│   │   │   │   └───widgets
│   │   │   │           step_1_basic_info.dart
│   │   │   │           step_2_security.dart
│   │   │   │           step_3_storage_path.dart
│   │   │   │           step_4_confirmation.dart
│   │   │   │
│   │   │   └───open_store
│   │   │       │   open_store.dart
│   │   │       │   open_store_control.dart
│   │   │       │
│   │   │       └───widgets
│   │   │               database_files_list.dart
│   │   │
│   │   ├───categories_manager
│   │   │   │   categories_manager.dart
│   │   │   │   categories_manager_control.dart
│   │   │   │   categories_manager_screen.dart
│   │   │   │
│   │   │   ├───categories_picker
│   │   │   │       categories_picker.dart
│   │   │   │       categories_picker_example.dart
│   │   │   │
│   │   │   ├───category_filter
│   │   │   │   │   category_filter.dart
│   │   │   │   │   category_filter_widget.dart
│   │   │   │   │   README.md
│   │   │   │   │   SUMMARY.md
│   │   │   │   │
│   │   │   │   ├───example
│   │   │   │   │       category_filter_example_screen.dart
│   │   │   │   │
│   │   │   │   └───widgets
│   │   │   │           category_filter_button.dart
│   │   │   │           category_filter_modal.dart
│   │   │   │
│   │   │   └───widgets
│   │   │           category_form_modal.dart
│   │   │           category_icon.dart
│   │   │
│   │   ├───dashboard
│   │   │   │   dashboard.dart
│   │   │   │   DATA_REFRESH_TRIGGER_GUIDE.md
│   │   │   │   README.md
│   │   │   │
│   │   │   ├───controllers
│   │   │   │   └───password_history
│   │   │   │           password_history_list_provider.dart
│   │   │   │
│   │   │   ├───futures
│   │   │   │   ├───notes_form
│   │   │   │   │       notes_form.dart
│   │   │   │   │       note_metadata_dialog.dart
│   │   │   │   │       time_stamp_embed.dart
│   │   │   │   │       toolbar.dart
│   │   │   │   │       youtube_video_player.dart
│   │   │   │   │
│   │   │   │   ├───otp_form
│   │   │   │   │       otp_edit_modal.dart
│   │   │   │   │       otp_form.dart
│   │   │   │   │       utils.dart
│   │   │   │   │
│   │   │   │   ├───password_form
│   │   │   │   │       password_form.dart
│   │   │   │   │       password_form_example.dart
│   │   │   │   │       password_form_screen.dart
│   │   │   │   │       password_form_state.dart
│   │   │   │   │       password_generator.dart
│   │   │   │   │
│   │   │   │   └───password_migration
│   │   │   │       │   CHANGELOG.md
│   │   │   │       │
│   │   │   │       ├───providers
│   │   │   │       │       migration_provider.dart
│   │   │   │       │
│   │   │   │       ├───screens
│   │   │   │       │       migration_screen.dart
│   │   │   │       │
│   │   │   │       └───services
│   │   │   │               json_generator_for_migration.dart
│   │   │   │               json_parser_for_migration.dart
│   │   │   │
│   │   │   ├───models
│   │   │   │       entety_type.dart
│   │   │   │       filter_tab.dart
│   │   │   │
│   │   │   ├───providers
│   │   │   │   │   data_refresh_trigger_provider.dart
│   │   │   │   │
│   │   │   │   ├───filter_providers
│   │   │   │   │       base_filter_provider.dart
│   │   │   │   │       entety_type_provider.dart
│   │   │   │   │       filter_providers.dart
│   │   │   │   │       filter_tabs_provider.dart
│   │   │   │   │       notes_filter_provider.dart
│   │   │   │   │       otp_filter_provider.dart
│   │   │   │   │       password_filter_provider.dart
│   │   │   │   │
│   │   │   │   └───lists_providers
│   │   │   │           paginated_notes_provider.dart
│   │   │   │           paginated_otps_provider.dart
│   │   │   │           paginated_passwords_provider.dart
│   │   │   │
│   │   │   ├───screens
│   │   │   │       dashboard_screen.dart
│   │   │   │       import_otp_screen.dart
│   │   │   │       password_history_screen.dart
│   │   │   │
│   │   │   └───widgets
│   │   │       │   dashboard_app_bar.dart
│   │   │       │   dashboard_filter_tabs_integration.dart
│   │   │       │   entity_action_modal.dart
│   │   │       │   entity_list_view.dart
│   │   │       │   entity_type_dropdown.dart
│   │   │       │   expandable_fab.dart
│   │   │       │   filter_modal.dart
│   │   │       │   filter_tabs.dart
│   │   │       │   PAGINATED_LIST_GUIDE.md
│   │   │       │
│   │   │       ├───cards
│   │   │       │       note_card.dart
│   │   │       │       otp_card.dart
│   │   │       │       password_card.dart
│   │   │       │       skeleton_card.dart
│   │   │       │
│   │   │       ├───filter_sections
│   │   │       │       base_filter_section.dart
│   │   │       │       filter_sections.dart
│   │   │       │       notes_filter_section.dart
│   │   │       │       otp_filter_section.dart
│   │   │       │       password_filter_section.dart
│   │   │       │
│   │   │       └───lists
│   │   │               empty_list.dart
│   │   │               notes_list.dart
│   │   │               otps_list.dart
│   │   │               passwords_list.dart
│   │   │
│   │   ├───icons_manager
│   │   │   │   icons.dart
│   │   │   │   icons_control.dart
│   │   │   │   icons_management_screen.dart
│   │   │   │
│   │   │   └───widgets
│   │   │           icon_card.dart
│   │   │           icon_filters.dart
│   │   │           icon_form.dart
│   │   │           icon_picker_button.dart
│   │   │           icon_picker_modal.dart
│   │   │           pagination_controls.dart
│   │   │           README.md
│   │   │           selectable_icon_card.dart
│   │   │
│   │   ├───otp
│   │   │   │   otp.dart
│   │   │   │   otp_controller.dart
│   │   │   │
│   │   │   ├───features
│   │   │   └───widgets
│   │   ├───qr_scaner
│   │   │       qr_scaner_screen.dart
│   │   │       qr_test_screen.dart
│   │   │
│   │   ├───sync
│   │   │   │   CLOUD_EXPORT_INTEGRATION.md
│   │   │   │   CLOUD_IMPORT_INTEGRATION.md
│   │   │   │
│   │   │   ├───providers
│   │   │   │       storage_export_provider.dart
│   │   │   │
│   │   │   ├───screens
│   │   │   │       export_confirm_screen.dart
│   │   │   │       export_screen.dart
│   │   │   │       import_screen.dart
│   │   │   │
│   │   │   ├───services
│   │   │   │       storage_export_service.dart
│   │   │   │
│   │   │   └───widgets
│   │   └───tags_manager
│   │       │   tags.dart
│   │       │   tags_management_control.dart
│   │       │   tags_management_screen.dart
│   │       │
│   │       ├───tags_picker
│   │       │       tags_picker.dart
│   │       │       tags_picker_example.dart
│   │       │
│   │       ├───tag_filter
│   │       │   │   README.md
│   │       │   │   SUMMARY.md
│   │       │   │   tag_filter.dart
│   │       │   │   tag_filter_widget.dart
│   │       │   │
│   │       │   ├───example
│   │       │   │       tag_filter_example_screen.dart
│   │       │   │
│   │       │   └───widgets
│   │       │           tag_filter_button.dart
│   │       │           tag_filter_modal.dart
│   │       │
│   │       └───widgets
│   │               tag_create_edit_modal.dart
│   │               tag_filters_widget.dart
│   │               tag_item_widget.dart
│   │               tag_selector_widget.dart
│   │
│   ├───settings
│   │   ├───screens
│   │   │       settings_screen.dart
│   │   │
│   │   └───widgets
│   │           notification_settings_widget.dart
│   │
│   ├───setup
│   │   │   index.dart
│   │   │   README.md
│   │   │   setup.dart
│   │   │
│   │   ├───providers
│   │   │       setup_provider.dart
│   │   │
│   │   └───widgets
│   │           permissions_screen.dart
│   │           theme_selection_screen.dart
│   │           welcome_screen.dart
│   │
│   ├───test
│   │   │   test.dart
│   │   │
│   │   └───widgets
│   │           test_scaffold_messenger.dart
│   │
│   └───titlebar
│           titlebar.dart
│           titlebar_control.dart
│
├───generated
│   └───migration_otp
│           index.dart
│           migration-payload.pb.dart
│           migration-payload.pbenum.dart
│           migration-payload.pbjson.dart
│
├───hoplixi_store
│   │   DATABASE_SCHEMA.md
│   │   hoplixi_store.dart
│   │   hoplixi_store.g.dart
│   │   hoplixi_store_manager.dart
│   │
│   ├───constants
│   │       pagination_constants.dart
│   │
│   ├───dao
│   │   │   attachments_dao.dart
│   │   │   attachments_dao.g.dart
│   │   │   categories_dao.dart
│   │   │   categories_dao.g.dart
│   │   │   icons_dao.dart
│   │   │   icons_dao.g.dart
│   │   │   index.dart
│   │   │   notes_dao.dart
│   │   │   notes_dao.g.dart
│   │   │   note_histories_dao.dart
│   │   │   note_histories_dao.g.dart
│   │   │   note_tags_dao.dart
│   │   │   note_tags_dao.g.dart
│   │   │   otps_dao.dart
│   │   │   otps_dao.g.dart
│   │   │   otp_histories_dao.dart
│   │   │   otp_histories_dao.g.dart
│   │   │   otp_tags_dao.dart
│   │   │   otp_tags_dao.g.dart
│   │   │   passwords_dao.dart
│   │   │   passwords_dao.g.dart
│   │   │   password_histories_dao.dart
│   │   │   password_histories_dao.g.dart
│   │   │   password_tags_dao.dart
│   │   │   password_tags_dao.g.dart
│   │   │   README.md
│   │   │   tags_dao.dart
│   │   │   tags_dao.g.dart
│   │   │
│   │   └───filters_dao
│   │           note_filter_dao.dart
│   │           note_filter_dao.g.dart
│   │           otp_filter_dao.dart
│   │           otp_filter_dao.g.dart
│   │           password_filter_dao.dart
│   │           password_filter_dao.g.dart
│   │
│   ├───dto
│   │       attachment_dto.dart
│   │       attachment_dto.freezed.dart
│   │       attachment_dto.g.dart
│   │       database_file_info.dart
│   │       db_dto.dart
│   │       db_dto.freezed.dart
│   │       db_dto.g.dart
│   │
│   ├───enums
│   │       entity_types.dart
│   │
│   ├───models
│   │   │   database_entry.dart
│   │   │   db_state.dart
│   │   │   db_state.freezed.dart
│   │   │
│   │   └───filter_models
│   │           attachments_filter.dart
│   │           attachments_filter.freezed.dart
│   │           attachments_filter.g.dart
│   │           base_filter.dart
│   │           base_filter.freezed.dart
│   │           base_filter.g.dart
│   │           notes_filter.dart
│   │           notes_filter.freezed.dart
│   │           notes_filter.g.dart
│   │           otp_filter.dart
│   │           otp_filter.freezed.dart
│   │           otp_filter.g.dart
│   │           password_filter.dart
│   │           password_filter.freezed.dart
│   │           password_filter.g.dart
│   │
│   ├───providers
│   │       dao_providers.dart
│   │       hoplixi_store_providers.dart
│   │       providers.dart
│   │       service_providers.dart
│   │
│   ├───repository
│   │       attachment_service.dart
│   │       categories_service.dart
│   │       icons_service.dart
│   │       index.dart
│   │       metadata_service.dart
│   │       notes_service.dart
│   │       password_service.dart
│   │       service_results.dart
│   │       tags_service.dart
│   │       totp_service.dart
│   │
│   ├───services
│   │       database_connection_service.dart
│   │       database_history_service.dart
│   │       database_validation_service.dart
│   │       history_service.dart
│   │       README.md
│   │       services.dart
│   │       trigger_management_service.dart
│   │
│   ├───sql
│   │   │   triggers.dart
│   │   │   TRIGGERS_DOCUMENTATION.md
│   │   │
│   │   └───triggers
│   │           history_delete_triggers.dart
│   │           history_update_triggers.dart
│   │           insert_timestamp_triggers.dart
│   │           meta_touch_triggers.dart
│   │           modified_at_triggers.dart
│   │
│   ├───tables
│   │       attachments.dart
│   │       categories.dart
│   │       hoplixi_meta.dart
│   │       icons.dart
│   │       index.dart
│   │       notes.dart
│   │       note_histories.dart
│   │       note_tags.dart
│   │       otps.dart
│   │       otp_histories.dart
│   │       otp_tags.dart
│   │       passwords.dart
│   │       password_histories.dart
│   │       password_tags.dart
│   │       tags.dart
│   │
│   └───utils
│           uuid_generator.dart
│
└───shared
    └───widgets
            app_lifecycle_indicator.dart
            button.dart
            close_database_button.dart
            database_closed_overlay.dart
            debouncer.dart
            filter_cache.dart
            index.dart
            password_field.dart
            shimmer_effect.dart
            slider_button.dart
            slider_button_loading_update.md
            text_field.dart

```