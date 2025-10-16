import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';

part 'auth_state.freezed.dart';

/// Состояние процесса авторизации
@freezed
class AuthState with _$AuthState {
  const factory AuthState.idle() = AuthStateIdle;

  const factory AuthState.validatingToken({
    required AuthClientConfig credential,
    required String returnPath,
  }) = AuthStateValidatingToken;

  const factory AuthState.authorizing({
    required AuthClientConfig credential,
    required String returnPath,
    String? message,
  }) = AuthStateAuthorizing;

  const factory AuthState.success({
    required String clientKey,
    required String returnPath,
  }) = AuthStateSuccess;

  const factory AuthState.failure({
    required String error,
    required AuthClientConfig credential,
    required String returnPath,
  }) = AuthStateFailure;

  const factory AuthState.cancelled({required String returnPath}) =
      AuthStateCancelled;
}

extension AuthStateX on AuthState {
  bool get isLoading =>
      this is AuthStateValidatingToken || this is AuthStateAuthorizing;

  bool get isIdle => this is AuthStateIdle;

  bool get isSuccess => this is AuthStateSuccess;

  bool get isFailure => this is AuthStateFailure;

  bool get isCancelled => this is AuthStateCancelled;

  String? get returnPath => maybeMap(
    validatingToken: (state) => state.returnPath,
    authorizing: (state) => state.returnPath,
    success: (state) => state.returnPath,
    failure: (state) => state.returnPath,
    cancelled: (state) => state.returnPath,
    orElse: () => null,
  );

  AuthClientConfig? get credential => maybeMap(
    validatingToken: (state) => state.credential,
    authorizing: (state) => state.credential,
    failure: (state) => state.credential,
    orElse: () => null,
  );

  String? get clientKey =>
      maybeMap(success: (state) => state.clientKey, orElse: () => null);

  String? get error =>
      maybeMap(failure: (state) => state.error, orElse: () => null);

  String? get message =>
      maybeMap(authorizing: (state) => state.message, orElse: () => null);
}
