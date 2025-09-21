import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';

part 'password_list_state.freezed.dart';

/// Состояние списка паролей с пагинацией
@freezed
abstract class PasswordListState with _$PasswordListState {
  const factory PasswordListState({
    /// Список паролей
    @Default([]) List<CardPasswordDto> passwords,

    /// Активный фильтр
    required PasswordFilter filter,

    /// Состояние загрузки
    @Default(false) bool isLoading,

    /// Состояние загрузки следующей страницы
    @Default(false) bool isLoadingMore,

    /// Есть ли еще страницы для загрузки
    @Default(true) bool hasMore,

    /// Ошибка загрузки
    String? error,

    /// Текущая страница
    @Default(0) int currentPage,

    /// Размер страницы
    @Default(20) int pageSize,

    /// Общее количество паролей
    @Default(0) int totalCount,
  }) = _PasswordListState;

  const PasswordListState._();

  /// Проверка на пустой список
  bool get isEmpty => passwords.isEmpty && !isLoading;

  /// Проверка есть ли данные
  bool get hasData => passwords.isNotEmpty;

  /// Проверка на состояние загрузки
  bool get isLoadingFirstPage => isLoading && passwords.isEmpty;

  /// Возвращает фильтр для текущей страницы
  PasswordFilter get currentFilter => filter.copyWith(
    base: filter.base.copyWith(limit: pageSize, offset: currentPage * pageSize),
  );

  /// Возвращает фильтр для следующей страницы
  PasswordFilter get nextPageFilter => filter.copyWith(
    base: filter.base.copyWith(
      limit: pageSize,
      offset: (currentPage + 1) * pageSize,
    ),
  );
}
