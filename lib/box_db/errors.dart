/// Errors for the box-based JSON-line key-value storage.
library;

/// Base error for all box-related errors.
abstract class BoxError implements Exception {
  final String message;
  final dynamic cause;

  const BoxError(this.message, [this.cause]);

  @override
  String toString() =>
      'BoxError: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Error in manifest operations.
class ManifestError extends BoxError {
  const ManifestError(super.message, [super.cause]);

  @override
  String toString() =>
      'ManifestError: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Error in segment operations.
class SegmentCorruptError extends BoxError {
  const SegmentCorruptError(super.message, [super.cause]);

  @override
  String toString() =>
      'SegmentCorruptError: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Error in decryption operations.
class DecryptionError extends BoxError {
  const DecryptionError(super.message, [super.cause]);

  @override
  String toString() =>
      'DecryptionError: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Error when encryption key is missing.
class KeyMissingError extends BoxError {
  const KeyMissingError(super.message, [super.cause]);

  @override
  String toString() =>
      'KeyMissingError: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Error in writer operations.
class WriterError extends BoxError {
  const WriterError(super.message, [super.cause]);

  @override
  String toString() =>
      'WriterError: $message${cause != null ? ' (cause: $cause)' : ''}';
}
