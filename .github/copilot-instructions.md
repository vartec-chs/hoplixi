# Hoplixi Development Guide for AI Agents

Hoplixi is a cross-platform Flutter password manager with local encrypted SQLite storage using SQLCipher and Drift ORM. The architecture follows a service-oriented pattern with Riverpod state management.

## Project Architecture

### Core Structure
- `lib/hoplixi_store/` - Main data layer using Drift ORM with 14 tables for passwords, TOTP, notes, categories, tags, and histories
- `lib/features/` - Feature modules (password_manager, setup, filters, etc.)
- `lib/core/` - Shared utilities, themes, logging, secure storage services
- `lib/router/` - GoRouter navigation with go_transitions

### Database Schema
- Uses UUID v4 for all primary keys for security
- Encrypted password and TOTP secret storage with nonce/cipher/tag pattern
- Comprehensive audit trail with history tables for all entities
- Foreign key constraints with CASCADE deletes
- See `lib/hoplixi_store/DATABASE_SCHEMA.md` for complete schema

### Key Patterns

**Service Layer Pattern**: All data operations use dedicated services returning `ServiceResult<T>`:
```dart
final result = await categoriesService.createCategory(name: 'Social', type: CategoryType.password);
if (result.success) { /* handle success */ }
```

**Riverpod State Management**: Use providers for dependency injection:
```dart
final storageProvider = Provider<StorageService>((ref) => StorageService());
```

**Drift Code Generation**: Run `build_runner.bat` or `dart run build_runner build --delete-conflicting-outputs` after schema changes.

## Development Workflow

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

Remember: This is a security-focused application. Always validate input, encrypt sensitive data, and follow the established patterns for data access through the service layer.