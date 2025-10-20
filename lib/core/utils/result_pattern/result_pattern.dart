/// Production-ready Result Pattern implementation.
///
/// Provides type-safe error handling using freezed sealed classes.
///
/// Basic usage:
/// ```dart
/// Result<User, AppError> result = await userService.getUser(id);
/// result.when(
///   success: (user) => print('Got user: ${user.name}'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
///
/// See [README.MD] for comprehensive documentation and examples.
library;

export 'result.dart';
export 'common_errors.dart';
