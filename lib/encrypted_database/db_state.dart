import 'package:freezed_annotation/freezed_annotation.dart';

part 'db_state.freezed.dart';

enum DatabaseStatus { closed, open, locked }

@freezed
abstract class DatabaseState with _$DatabaseState {
  const factory DatabaseState({
    String? path,
    String? name,
    @Default(DatabaseStatus.closed) DatabaseStatus status,
    String? error,
  }) = _DatabaseState;

  const DatabaseState._();

  bool get isOpen => status == DatabaseStatus.open;
  bool get isClosed => status == DatabaseStatus.closed;
  bool get isLocked => status == DatabaseStatus.locked;
}
