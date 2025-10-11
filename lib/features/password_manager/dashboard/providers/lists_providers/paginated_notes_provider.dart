import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/base_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/notes_filter.dart';
import 'package:hoplixi/hoplixi_store/providers/dao_providers.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import '../filter_providers/notes_filter_provider.dart';
import '../filter_providers/filter_tabs_provider.dart';
import '../data_refresh_trigger_provider.dart';
import '../../models/filter_tab.dart';

/// Размер страницы для пагинации
const int kNotesPageSize = 20;

/// Состояние пагинированного списка заметок
class PaginatedNotesState {
  final List<CardNoteDto> notes;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final int totalCount;

  const PaginatedNotesState({
    this.notes = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.totalCount = 0,
  });

  PaginatedNotesState copyWith({
    List<CardNoteDto>? notes,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    int? totalCount,
  }) {
    return PaginatedNotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  String toString() {
    return 'PaginatedNotesState('
        'notes: ${notes.length}, '
        'isLoading: $isLoading, '
        'isLoadingMore: $isLoadingMore, '
        'hasMore: $hasMore, '
        'error: $error, '
        'currentPage: $currentPage, '
        'totalCount: $totalCount)';
  }
}

/// Провайдер для пагинированного списка заметок
final paginatedNotesProvider =
    AsyncNotifierProvider<PaginatedNotesNotifier, PaginatedNotesState>(
      () => PaginatedNotesNotifier(),
    );

class PaginatedNotesNotifier extends AsyncNotifier<PaginatedNotesState> {
  @override
  Future<PaginatedNotesState> build() async {
    logDebug('PaginatedNotesNotifier: Инициализация');

    // Слушаем состояние базы данных
    ref.listen(isDatabaseOpenProvider, (previous, next) {
      if (previous != next) {
        if (next) {
          logDebug(
            'PaginatedNotesNotifier: База данных открыта, перезагружаем данные',
          );
          // Задержка для обеспечения готовности всех провайдеров
          Future.delayed(const Duration(milliseconds: 300), () {
            if (ref.mounted) {
              _resetAndLoad();
            }
          });
        } else {
          logDebug(
            'PaginatedNotesNotifier: База данных закрыта, очищаем данные',
          );
          // При закрытии базы данных очищаем данные
          if (ref.mounted) {
            state = const AsyncValue.data(PaginatedNotesState());
          }
        }
      }
    });

    // Слушаем изменения фильтра заметок
    ref.listen(notesFilterProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedNotesNotifier: Изменение фильтра заметок');
        _resetAndLoad();
      }
    });

    // Слушаем изменения вкладок фильтров
    ref.listen(filterTabsControllerProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedNotesNotifier: Изменение вкладки фильтра');
        _resetAndLoad();
      }
    });

    // Слушаем триггер обновления данных
    ref.listen(dataRefreshTriggerProvider, (previous, next) {
      if (previous != next && ref.read(isDatabaseOpenProvider)) {
        logDebug('PaginatedNotesNotifier: Триггер обновления данных');
        _resetAndLoad();
      }
    });

    return _loadInitialData();
  }

  /// Загружает начальные данные
  Future<PaginatedNotesState> _loadInitialData() async {
    try {
      logDebug(
        'PaginatedNotesNotifier: Загрузка начальных данных',
        tag: 'PaginatedNotesNotifier',
      );

      // Проверяем, что база данных открыта
      final isDatabaseOpen = ref.read(isDatabaseOpenProvider);
      if (!isDatabaseOpen) {
        logDebug(
          'PaginatedNotesNotifier: База данных не открыта, возвращаем пустое состояние',
        );
        return const PaginatedNotesState();
      }

      // Проверяем доступность DAO
      try {
        final dao = ref.read(noteFilterDaoProvider);
        logDebug('PaginatedNotesNotifier: DAO получен успешно');

        // Проверяем доступность базы данных через DAO
        final testCount = await dao.countFilteredNotes(
          NotesFilter.create().copyWith(
            base: BaseFilter.create().copyWith(limit: 1, offset: 0),
          ),
        );
        logDebug(
          'PaginatedNotesNotifier: Тестовый запрос к БД выполнен, результат: $testCount',
        );
      } catch (e, s) {
        logError(
          'PaginatedNotesNotifier: Ошибка доступа к DAO или БД',
          error: e,
          stackTrace: s,
        );
        return PaginatedNotesState(
          error: 'Ошибка доступа к базе данных: ${e.toString()}',
          isLoading: false,
        );
      }

      final filter = _buildCurrentFilter();
      final dao = ref.read(noteFilterDaoProvider);

      // Загружаем первую страницу
      final notes = await dao.getFilteredNotes(filter);
      final totalCount = await dao.countFilteredNotes(filter);

      logDebug(
        'PaginatedNotesNotifier: Загружено ${notes.length} заметок, всего: $totalCount',
      );

      return PaginatedNotesState(
        notes: notes,
        isLoading: false,
        hasMore: notes.length >= kNotesPageSize && notes.length < totalCount,
        currentPage: 1,
        totalCount: totalCount,
      );
    } catch (e, s) {
      logError(
        'PaginatedNotesNotifier: Ошибка загрузки начальных данных',
        error: e,
        stackTrace: s,
      );
      return PaginatedNotesState(
        error: 'Ошибка загрузки данных: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Загружает следующую страницу данных
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore ||
        !ref.read(isDatabaseOpenProvider)) {
      return;
    }

    try {
      logDebug('PaginatedNotesNotifier: Загрузка следующей страницы');

      // Устанавливаем состояние загрузки
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

      final filter = _buildCurrentFilter(page: currentState.currentPage + 1);
      final dao = ref.read(noteFilterDaoProvider);

      final newNotes = await dao.getFilteredNotes(filter);

      logDebug(
        'PaginatedNotesNotifier: Загружено дополнительно ${newNotes.length} заметок',
      );

      final allNotes = [...currentState.notes, ...newNotes];
      final hasMore =
          newNotes.length >= kNotesPageSize &&
          allNotes.length < currentState.totalCount;

      state = AsyncValue.data(
        currentState.copyWith(
          notes: allNotes,
          isLoadingMore: false,
          hasMore: hasMore,
          currentPage: currentState.currentPage + 1,
        ),
      );
    } catch (e, s) {
      logError(
        'PaginatedNotesNotifier: Ошибка загрузки дополнительных данных',
        error: e,
        stackTrace: s,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          error: 'Ошибка загрузки дополнительных данных: ${e.toString()}',
        ),
      );
    }
  }

  /// Обновляет данные (pull-to-refresh)
  Future<void> refresh() async {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(isLoading: true));
      try {
        final newState = await _loadInitialData();
        state = AsyncValue.data(newState);
      } catch (e) {
        state = AsyncValue.data(
          currentState.copyWith(isLoading: false, error: e.toString()),
        );
      }
    } else {
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(_loadInitialData);
    }
  }

  /// Переключение избранного состояния заметки с оптимистичным обновлением UI
  Future<void> toggleFavorite(String noteId) async {
    final currentState = state.value;
    if (currentState == null || !ref.read(isDatabaseOpenProvider)) return;

    try {
      // Находим заметку в текущем списке
      final noteIndex = currentState.notes.indexWhere((n) => n.id == noteId);
      if (noteIndex == -1) return;

      final note = currentState.notes[noteIndex];
      final newFavoriteState = !(note.isFavorite ?? false);

      logDebug(
        'PaginatedNotesNotifier: Переключение избранного для заметки $noteId: ${note.isFavorite} -> $newFavoriteState',
      );

      // Проверяем текущую вкладку фильтра
      final currentTab = ref.read(filterTabsControllerProvider);

      // Если текущая вкладка - "Избранные" и мы убираем из избранных,
      // удаляем заметку из списка
      if (currentTab == FilterTab.favorites && !newFavoriteState) {
        logDebug(
          'PaginatedNotesNotifier: Удаление заметки $noteId из списка избранных',
        );

        final updatedNotes = [...currentState.notes];
        updatedNotes.removeAt(noteIndex);

        state = AsyncValue.data(
          currentState.copyWith(
            notes: updatedNotes,
            totalCount: currentState.totalCount - 1,
          ),
        );

        // Обновляем в базе данных
        final service = ref.read(notesServiceProvider);
        final result = await service.updateNote(
          UpdateNoteDto(id: noteId, isFavorite: newFavoriteState),
        );

        if (!result.success) {
          // Откатываем изменения при ошибке - возвращаем заметку в список
          updatedNotes.insert(noteIndex, note);
          state = AsyncValue.data(
            currentState.copyWith(
              notes: updatedNotes,
              totalCount: currentState.totalCount,
            ),
          );
          logError(
            'PaginatedNotesNotifier: Ошибка при обновлении избранного: ${result.message}',
          );
        } else {
          logDebug(
            'PaginatedNotesNotifier: Избранное успешно обновлено для заметки $noteId',
          );
        }
      } else {
        // Стандартное поведение - обновляем состояние заметки
        final updatedNotes = [...currentState.notes];
        updatedNotes[noteIndex] = note.copyWith(isFavorite: newFavoriteState);

        state = AsyncValue.data(currentState.copyWith(notes: updatedNotes));

        // Обновляем в базе данных
        final service = ref.read(notesServiceProvider);
        final result = await service.updateNote(
          UpdateNoteDto(id: noteId, isFavorite: newFavoriteState),
        );

        if (!result.success) {
          // Откатываем изменения при ошибке
          updatedNotes[noteIndex] = note;
          state = AsyncValue.data(currentState.copyWith(notes: updatedNotes));
          logError(
            'PaginatedNotesNotifier: Ошибка при обновлении избранного: ${result.message}',
          );
        } else {
          logDebug(
            'PaginatedNotesNotifier: Избранное успешно обновлено для заметки $noteId',
          );
        }
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refresh();
      logError(
        'PaginatedNotesNotifier: Ошибка при переключении избранного',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Переключение закрепленного состояния заметки с оптимистичным обновлением UI
  Future<void> togglePinned(String noteId) async {
    final currentState = state.value;
    if (currentState == null || !ref.read(isDatabaseOpenProvider)) return;

    try {
      // Находим заметку в текущем списке
      final noteIndex = currentState.notes.indexWhere((n) => n.id == noteId);
      if (noteIndex == -1) return;

      final note = currentState.notes[noteIndex];
      final newPinnedState = !(note.isPinned ?? false);

      logDebug(
        'PaginatedNotesNotifier: Переключение закрепления для заметки $noteId: ${note.isPinned} -> $newPinnedState',
      );

      // Оптимистично обновляем состояние заметки
      final updatedNotes = [...currentState.notes];
      updatedNotes[noteIndex] = note.copyWith(isPinned: newPinnedState);

      // Если закрепляем, перемещаем в начало списка
      // Если открепляем, оставляем на месте (пересортировка произойдет при обновлении)
      if (newPinnedState) {
        final pinnedNote = updatedNotes.removeAt(noteIndex);
        updatedNotes.insert(0, pinnedNote);
      }

      state = AsyncValue.data(currentState.copyWith(notes: updatedNotes));

      // Обновляем в базе данных
      final service = ref.read(notesServiceProvider);
      final result = await service.updateNote(
        UpdateNoteDto(id: noteId, isPinned: newPinnedState),
      );

      if (!result.success) {
        // Откатываем изменения при ошибке
        await refresh();
        logError(
          'PaginatedNotesNotifier: Ошибка при обновлении закрепления: ${result.message}',
        );
      } else {
        logDebug(
          'PaginatedNotesNotifier: Закрепление успешно обновлено для заметки $noteId',
        );
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refresh();
      logError(
        'PaginatedNotesNotifier: Ошибка при переключении закрепления',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Удаление заметки с оптимистичным обновлением UI
  Future<void> deleteNote(String noteId) async {
    final currentState = state.value;
    if (currentState == null || !ref.read(isDatabaseOpenProvider)) return;

    try {
      // Находим заметку в текущем списке
      final noteIndex = currentState.notes.indexWhere((n) => n.id == noteId);
      if (noteIndex == -1) return;

      final note = currentState.notes[noteIndex];

      logDebug('PaginatedNotesNotifier: Удаление заметки $noteId');

      // Оптимистично удаляем заметку из UI
      final updatedNotes = [...currentState.notes];
      updatedNotes.removeAt(noteIndex);

      state = AsyncValue.data(
        currentState.copyWith(
          notes: updatedNotes,
          totalCount: currentState.totalCount - 1,
        ),
      );

      // Удаляем заметку из базы данных
      final service = ref.read(notesServiceProvider);
      final result = await service.deleteNote(noteId);

      if (!result.success) {
        // Откатываем изменения при ошибке - возвращаем заметку в список
        updatedNotes.insert(noteIndex, note);
        state = AsyncValue.data(
          currentState.copyWith(
            notes: updatedNotes,
            totalCount: currentState.totalCount,
          ),
        );
        logError(
          'PaginatedNotesNotifier: Ошибка при удалении заметки: ${result.message}',
        );
      } else {
        logDebug('PaginatedNotesNotifier: Заметка $noteId успешно удалена');
      }
    } catch (e, stackTrace) {
      // Перезагружаем список при критической ошибке
      await refresh();
      logError(
        'PaginatedNotesNotifier: Ошибка при удалении заметки',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Сбрасывает состояние и загружает данные заново
  void _resetAndLoad() {
    if (!ref.read(isDatabaseOpenProvider)) {
      logDebug(
        'PaginatedNotesNotifier: База данных не открыта, пропускаем сброс и загрузку',
      );
      return;
    }

    logDebug('PaginatedNotesNotifier: Сброс и перезагрузка');
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }

  /// Строит текущий фильтр с учетом пагинации
  NotesFilter _buildCurrentFilter({int page = 1}) {
    final notesFilter = ref.read(notesFilterProvider);
    final currentTab = ref.read(filterTabsControllerProvider);

    logDebug(
      'PaginatedNotesNotifier: Построение фильтра для страницы $page, вкладка: $currentTab',
    );

    // Применяем фильтр текущей вкладки к базовому фильтру
    final tabFilter = _getTabFilter(currentTab);
    final baseFilter = notesFilter.base.copyWith(
      isFavorite: tabFilter,
      limit: kNotesPageSize,
      offset: (page - 1) * kNotesPageSize,
    );

    final finalFilter = notesFilter.copyWith(base: baseFilter);

    logDebug(
      'PaginatedNotesNotifier: Фильтр построен - '
      'isFavorite: ${baseFilter.isFavorite}, '
      'limit: ${baseFilter.limit}, '
      'offset: ${baseFilter.offset}, '
      'searchQuery: ${baseFilter.query}',
    );

    return finalFilter;
  }

  /// Получает текущее количество заметок
  int get currentCount => state.value?.notes.length ?? 0;

  /// Проверяет, есть ли еще данные для загрузки
  bool get hasMore => state.value?.hasMore ?? false;

  /// Проверяет, идет ли загрузка дополнительных данных
  bool get isLoadingMore => state.value?.isLoadingMore ?? false;

  /// Получает список заметок
  List<CardNoteDto> get notes => state.value?.notes ?? [];

  /// Получает общее количество заметок
  int get totalCount => state.value?.totalCount ?? 0;

  /// Получает фильтр для вкладки
  bool? _getTabFilter(FilterTab tab) {
    switch (tab) {
      case FilterTab.all:
        return null;
      case FilterTab.favorites:
        return true;
      case FilterTab.frequent:
        return null; // Для заметок не применимо
      case FilterTab.archived:
        return null; // Для заметок не применимо
    }
  }
}
