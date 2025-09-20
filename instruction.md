# Hoplixi Development Guide for AI Agents

Hoplixi is a cross-platform Flutter password manager with local encrypted SQLite storage using SQLCipher and Drift ORM. The architecture follows a service-oriented pattern with Riverpod state management version 3 Notifi Api only, not use legacy api.

## Project Architecture

### Core Structure

- `lib/hoplixi_store/` - Main data layer using Drift ORM with 14 tables for passwords, TOTP, notes, categories, tags, and histories
- `lib/features/` - Feature modules (password_manager, setup, filters, etc.)
- `lib/core/` - Shared utilities, themes, logging, secure storage services
- `lib/router/` - GoRouter navigation with go_transitions

### Base

- Use Logger: import 'package:hoplixi/core/logger/app_logger.dart';
- Use custom decoration text field: import 'package:hoplixi/common/text_field.dart';
- Use custom decoration password field: import 'package:hoplixi/common/password_field.dart';
- Use custom button: import 'package:hoplixi/common/button.dart';
- Use Toastification: import 'package:hoplixi/core/utils/toastification.dart';
- Use slider button for confirmation: import 'package:hoplixi/common/slider_button.dart';

### In project main dependencies

- Use GoRouter: import 'package:go_router/go_router.dart';
- Use Riverpod v3 only Notifi api no legacy: import 'package:flutter_riverpod/flutter_riverpod.dart';
- Use Flutter Material: import 'package:flutter/material.dart';
- for all dependencies see pubspec.yaml

### In project features dependencies

- Use custom colors: import 'package:hoplixi/core/theme/app_colors.dart';

### Code Generation

- Always run build_runner after modifying Drift tables, Freezed classes, or JSON serialization
- Use the provided `build_runner.bat` script for convenience
- Generated files have `.g.dart` and `.freezed.dart` extensions

### Security Requirements

- All sensitive data (passwords, TOTP secrets) must use the `CryptoManager` encryption pattern
- Store encrypted data with nonce, cipher, and authentication tag
- Never log sensitive data - use `logDebug()` functions from `app_logger.dart`

### Testing

- Database tests use in-memory SQLite with trigger validation
- Widget tests for UI components in `test/` directory
- Use `flutter test` for running tests

### Platform Support

- Supports Windows, macOS, Linux, Android, iOS
- Web platform explicitly disabled (throws `UnsupportedError`)
- Uses `universal_platform` for platform detection

## Common Tasks

### Adding New Database Table

1. Create table class in `lib/hoplixi_store/tables/`
2. Add DAO class in `lib/hoplixi_store/dao/`
3. Update `hoplixi_store.dart` to include table and DAO
4. Run build_runner to generate code
5. Create service class following existing patterns

### Creating New Feature

1. Add feature directory under `lib/features/`
2. Follow existing structure: screens, widgets, providers
3. Add routes in `lib/router/routes.dart`
4. Use responsive framework breakpoints for adaptive UI

### Error Handling

- Use `AppLogger` for all logging with appropriate levels
- Toast notifications via `ToastHelper` for user feedback
- Global error handling in `main.dart` catches Flutter and platform errors
- Service layer returns structured results, never throws exceptions

### UI Conventions

- Use `ResponsiveFramework` with predefined breakpoints (MOBILE, TABLET, DESKTOP)
- Theme management through `themeProvider` with light/dark modes
- Google Fonts integration for typography
- Material Design 3 with FlexColorScheme for consistent theming

### MCP Servers

- To obtain accurate data about libraries, use mcp server context7;
- Use an MCP server for the SequentialThinking model when you need reliable, ordered orchestration of multi-step reasoning — e.g., to manage long-running, stateful chains of inference, coordinate parallel subtasks, or persist and resume multi-turn workflows.
Also use it when you need centralized routing, authentication, load-balancing and observability (logging/metrics) for many clients or models so ordering, fault tolerance and scalable performance are maintained.