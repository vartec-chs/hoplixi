import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/dao/index.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/providers/dao_providers.dart';

class PasswordHistoryListController
    extends AsyncNotifier<List<PasswordHistory>> {
  PasswordHistoryListController(this.passwordId);
  String passwordId;

  late PasswordHistoriesDao _passwordHistoriesDao;

  @override
  Future<List<PasswordHistory>> build() async {
    state = const AsyncValue.loading();
    _passwordHistoriesDao = ref.read(passwordsHistoryDaoProvider);
    return loadPasswordHistory();
  }

  Future<List<PasswordHistory>> loadPasswordHistory() {
    return _passwordHistoriesDao.getPasswordHistory(passwordId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final histories = await loadPasswordHistory();
    state = AsyncValue.data(histories);
  }

  /// Оптимистичное удаление элемента из истории
  Future<void> optimisticDelete(String historyId) async {
    final currentHistories = state.maybeWhen(
      data: (histories) => histories,
      orElse: () => <PasswordHistory>[],
    );

    // Найти элемент для удаления
    final historyToDelete = currentHistories.firstWhere(
      (h) => h.id == historyId,
      orElse: () => throw Exception('History entry not found'),
    );

    // Создать новый список без удаляемого элемента
    final updatedHistories = currentHistories
        .where((h) => h.id != historyId)
        .toList();

    // Обновить состояние оптимистично
    state = AsyncValue.data(updatedHistories);

    try {
      // Попытаться удалить из базы данных
      final deletedCount = await _passwordHistoriesDao.deleteHistoryEntry(
        historyId,
      );

      if (deletedCount == 0) {
        // Если не удалось удалить, восстановить элемент
        final restoredHistories = [...updatedHistories, historyToDelete]
          ..sort(
            (a, b) => b.actionAt.compareTo(a.actionAt),
          ); // Сортировка по дате убывания
        state = AsyncValue.data(restoredHistories);
        // Здесь можно добавить уведомление об ошибке
      }
    } catch (error) {
      // В случае ошибки восстановить элемент
      final restoredHistories = [...updatedHistories, historyToDelete]
        ..sort((a, b) => b.actionAt.compareTo(a.actionAt));
      state = AsyncValue.data(restoredHistories);
      // Здесь можно добавить уведомление об ошибке
    }
  }
}

final passwordHistoryListProvider = AsyncNotifierProvider.family
    .autoDispose<PasswordHistoryListController, List<PasswordHistory>, String>(
      (arg) => PasswordHistoryListController(arg),
    );
