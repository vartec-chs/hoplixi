# Hoplixi Development Guide for AI Agents

Hoplixi is a cross-platform Flutter password manager with local encrypted SQLite storage using SQLCipher and Drift ORM. The architecture follows a service-oriented pattern with **Riverpod v3 (Notifier API only)**.

## Project Architecture

### Core Structure
- `lib/hoplixi_store/` - Data layer: 14 tables with Drift ORM, DAOs, services, triggers, and schema migrations
- `lib/features/` - Feature modules organized by domain (password_manager, setup, home, titlebar)
- `lib/common/` - Reusable UI components (SmoothButton, password_field, slider_button, text_field)
- `lib/core/` - Infrastructure: themes, logging, preferences, secure storage, error handling
- `lib/router/` - GoRouter navigation with go_transitions for smooth transitions

### Critical Dependencies & Imports
**Always use project-specific components:**
```dart
// Logging (mandatory for all operations)
import 'package:hoplixi/core/logger/app_logger.dart';

// UI Components (use instead of generic Flutter widgets)
import 'package:hoplixi/common/text_field.dart';      // Custom styled text fields
import 'package:hoplixi/common/password_field.dart';  // Secure password input
import 'package:hoplixi/common/button.dart';          // SmoothButton with types/sizes
import 'package:hoplixi/common/slider_button.dart';   // Confirmation slider

// Utilities
import 'package:hoplixi/core/utils/toastification.dart'; // Toast notifications
import 'package:hoplixi/core/app_preferences/index.dart'; // SharedPreferences wrapper
import 'package:hoplixi/core/theme/colors.dart';          // FlexColorScheme colors
```

### Database & Encryption Architecture

**Service Layer Pattern** - All data operations through services returning `ServiceResult<T>`:
```dart
// Example from PasswordService
final result = await passwordService.createPassword(createDto, tagIds: ['uuid1', 'uuid2']);
if (result.success) {
  // result.data contains the password ID
} else {
  ToastHelper.error(result.message);
}
```

**Encryption Pattern** - Sensitive data stored with nonce/cipher/tag triad:
- Passwords: `password` field contains encrypted data
- TOTP secrets: `secret` field encrypted, stored with `secret_nonce`, `secret_cipher`, `secret_tag`
- All primary keys are UUID v4 for security

**Database Schema** - See `lib/hoplixi_store/DATABASE_SCHEMA.md`:
- 14 tables with comprehensive history tracking
- SQL triggers automatically maintain history tables on UPDATE/DELETE
- Foreign key constraints with CASCADE deletes

## Development Workflow

### Code Generation (Critical)
```bash
# Use the provided batch file (Windows)
build_runner.bat

# Or run manually
dart run build_runner build --delete-conflicting-outputs
```
**Required after:**
- Modifying any Drift table in `lib/hoplixi_store/tables/`
- Adding/changing Freezed classes
- Updating JSON serialization

### Service Architecture Pattern
When adding new database entities:

1. **Create table**: `lib/hoplixi_store/tables/your_table.dart`
2. **Create DAO**: `lib/hoplixi_store/dao/your_dao.dart` 
3. **Update store**: Add to `@DriftDatabase` in `hoplixi_store.dart`
4. **Run build_runner** to generate `.g.dart` files
5. **Create service**: `lib/hoplixi_store/services/your_service.dart` following `PasswordService` pattern
6. **Add triggers**: Update `lib/hoplixi_store/sql/triggers.dart` for history tracking

### Security & Logging Requirements

**Never log sensitive data** - Use structured logging:
```dart
logInfo('Creating password entry', tag: 'PasswordService', data: {'name': dto.name}); // Good
logError('Password creation failed', error: e, tag: 'PasswordService'); // Good
logDebug('Password: ${password}', tag: 'Debug'); // NEVER - exposes sensitive data
```

**Error Handling** - Services never throw, always return `ServiceResult`:
```dart
try {
  // Database operation
  return ServiceResult.success(data: result);
} catch (e) {
  logError('Operation failed', error: e, tag: 'ServiceTag');
  return ServiceResult.error('User-friendly error message');
}
```

### UI & Theming Conventions

**Responsive Design** - Use breakpoints from `ResponsiveFramework`:
- MOBILE: 450px and below
- TABLET: 451px to 1000px  
- DESKTOP: 1001px and above

**Theme System** - Material Design 3 with FlexColorScheme:
```dart
// Access theme colors
final colors = ref.watch(themeProvider).colorScheme;
// Custom app colors
import 'package:hoplixi/core/theme/colors.dart'; // AppColors.lightColors/darkColors
```

**Component Patterns**:
```dart
// Use SmoothButton instead of ElevatedButton/TextButton
SmoothButton(
  type: SmoothButtonType.filled,    // filled, outlined, tonal, text
  size: SmoothButtonSize.medium,    // small, medium, large
  label: 'Create Password',
  onPressed: () => handleAction(),
)

// Use slider for destructive confirmations
SliderButton(onConfirm: () => deletePassword())
```

## Platform & Deployment

**Supported Platforms**: Windows ✅, Android ✅, macOS/Linux/iOS (untested)
**Web explicitly disabled** - throws `UnsupportedError` in main.dart

**Window Management**: Uses `window_manager` for desktop window control, initialized in `main.dart`

**Build Commands**:
- `flutter build windows` for Windows deployment
- `flutter build apk` for Android APK
- Use `release.bat` for automated release builds

## Key Architecture Decisions

1. **Riverpod v3 Notifier API only** - No legacy Consumer/ConsumerWidget patterns
2. **Service-First Architecture** - UI never directly accesses DAOs, always through services
3. **Comprehensive History Tracking** - All CRUD operations automatically logged via SQL triggers
4. **Security by Design** - UUID keys, encrypted storage, no sensitive logging, platform restrictions
5. **Responsive Mobile-First** - Desktop features are enhancements, not requirements

This architecture prioritizes security, maintainability, and cross-platform consistency while maintaining Flutter/Dart best practices.

## MCP Servers

- To obtain accurate data about libraries, use mcp server context7;
- Use an MCP server for the SequentialThinking model when you need reliable, ordered orchestration of multi-step reasoning — e.g., to manage long-running, stateful chains of inference, coordinate parallel subtasks, or persist and resume multi-turn workflows.
Also use it when you need centralized routing, authentication, load-balancing and observability (logging/metrics) for many clients or models so ordering, fault tolerance and scalable performance are maintained.