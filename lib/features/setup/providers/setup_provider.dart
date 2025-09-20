import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Enum для типов экранов setup
enum SetupScreenType { welcome, themeSelection, permissions }

/// Модель состояния setup процесса
class SetupState {
  final int currentIndex;
  final List<SetupScreenType> screens;
  final bool isCompleted;
  final Map<SetupScreenType, bool> completedScreens;

  const SetupState({
    required this.currentIndex,
    required this.screens,
    required this.isCompleted,
    required this.completedScreens,
  });

  SetupState copyWith({
    int? currentIndex,
    List<SetupScreenType>? screens,
    bool? isCompleted,
    Map<SetupScreenType, bool>? completedScreens,
  }) {
    return SetupState(
      currentIndex: currentIndex ?? this.currentIndex,
      screens: screens ?? this.screens,
      isCompleted: isCompleted ?? this.isCompleted,
      completedScreens: completedScreens ?? this.completedScreens,
    );
  }

  bool get canGoNext => currentIndex < screens.length - 1;
  bool get canGoPrevious => currentIndex > 0;
  SetupScreenType get currentScreen => screens[currentIndex];

  bool isScreenCompleted(SetupScreenType screen) =>
      completedScreens[screen] ?? false;
}

/// Notifier для управления состоянием setup процесса
class SetupNotifier extends Notifier<SetupState> {
  @override
  SetupState build() {
    logDebug('Инициализация SetupNotifier');
    return const SetupState(
      currentIndex: 0,
      screens: [
        SetupScreenType.welcome,
        SetupScreenType.themeSelection,
        SetupScreenType.permissions,
      ],
      isCompleted: false,
      completedScreens: {},
    );
  }

  /// Переход к следующему экрану
  void nextScreen() {
    if (state.canGoNext) {
      logDebug('Переход к следующему экрану: ${state.currentIndex + 1}');
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Переход к предыдущему экрану
  void previousScreen() {
    if (state.canGoPrevious) {
      logDebug('Переход к предыдущему экрану: ${state.currentIndex - 1}');
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Переход к конкретному экрану
  void goToScreen(int index) {
    if (index >= 0 && index < state.screens.length) {
      logDebug('Переход к экрану с индексом: $index');
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Отметить экран как завершенный
  void markScreenCompleted(SetupScreenType screen) {
    logDebug('Отметка экрана как завершенного: $screen');
    final completedScreens = Map<SetupScreenType, bool>.from(
      state.completedScreens,
    );
    completedScreens[screen] = true;

    // Проверить, завершены ли все экраны
    final allCompleted = state.screens.every(
      (screen) => completedScreens[screen] == true,
    );

    state = state.copyWith(
      completedScreens: completedScreens,
      isCompleted: allCompleted,
    );
  }

  /// Добавить новый экран в последовательность
  void addScreen(SetupScreenType screen, {int? atIndex}) {
    logDebug('Добавление нового экрана: $screen');
    final screens = List<SetupScreenType>.from(state.screens);

    if (atIndex != null && atIndex >= 0 && atIndex <= screens.length) {
      screens.insert(atIndex, screen);
    } else {
      screens.add(screen);
    }

    state = state.copyWith(screens: screens);
  }

  /// Удалить экран из последовательности
  void removeScreen(SetupScreenType screen) {
    logDebug('Удаление экрана: $screen');
    final screens = List<SetupScreenType>.from(state.screens);
    screens.remove(screen);

    // Если текущий индекс больше длины нового списка, скорректировать его
    int newIndex = state.currentIndex;
    if (newIndex >= screens.length) {
      newIndex = screens.length - 1;
    }

    final completedScreens = Map<SetupScreenType, bool>.from(
      state.completedScreens,
    );
    completedScreens.remove(screen);

    state = state.copyWith(
      screens: screens,
      currentIndex: newIndex,
      completedScreens: completedScreens,
    );
  }

  /// Сброс setup процесса
  void reset() {
    logDebug('Сброс setup процесса');
    state = SetupState(
      currentIndex: 0,
      screens: state.screens,
      isCompleted: false,
      completedScreens: {},
    );
  }
}

/// Provider для состояния setup процесса
final setupProvider = NotifierProvider<SetupNotifier, SetupState>(() {
  return SetupNotifier();
});

/// Provider для PageController
final pageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController();

  // Слушать изменения состояния setup и обновлять PageController
  ref.listen<SetupState>(setupProvider, (previous, next) {
    if (previous?.currentIndex != next.currentIndex) {
      controller.animateToPage(
        next.currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  });

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});
