// Контроллер управления иконками
// Этот файл может содержать дополнительную бизнес-логику для управления иконками

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Провайдер для управления состоянием экрана иконок
final iconsScreenStateProvider =
    StateNotifierProvider<IconsScreenStateNotifier, IconsScreenState>((ref) {
      return IconsScreenStateNotifier();
    });

/// Состояние экрана иконок
class IconsScreenState {
  final IconType? selectedType;
  final String searchQuery;
  final int currentPage;
  final bool isGridView;
  final bool isLoading;

  const IconsScreenState({
    this.selectedType,
    this.searchQuery = '',
    this.currentPage = 1,
    this.isGridView = true,
    this.isLoading = false,
  });

  IconsScreenState copyWith({
    IconType? selectedType,
    String? searchQuery,
    int? currentPage,
    bool? isGridView,
    bool? isLoading,
  }) {
    return IconsScreenState(
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      isGridView: isGridView ?? this.isGridView,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier для управления состоянием экрана иконок
class IconsScreenStateNotifier extends StateNotifier<IconsScreenState> {
  IconsScreenStateNotifier() : super(const IconsScreenState());

  void setFilter(IconType? type) {
    state = state.copyWith(selectedType: type, currentPage: 1);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void toggleViewMode() {
    state = state.copyWith(isGridView: !state.isGridView);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}
