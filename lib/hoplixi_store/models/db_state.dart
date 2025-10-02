import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/core/errors/db_errors.dart';

part 'db_state.freezed.dart';

enum DatabaseStatus { closed, open, locked, loading, error }

@freezed
abstract class DatabaseState with _$DatabaseState {
  const factory DatabaseState({
    String? path,
    String? name,
    @Default(DatabaseStatus.closed) DatabaseStatus status,
    DatabaseError? error,
  }) = _DatabaseState;

  const DatabaseState._();

  bool get isOpen => status == DatabaseStatus.open;
  bool get isClosed => status == DatabaseStatus.closed;
  bool get isLocked => status == DatabaseStatus.locked;
  bool get isLoading => status == DatabaseStatus.loading;
  bool get hasError => status == DatabaseStatus.error;
}
