import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/lists_providers/paginated_passwords_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/lists_providers/paginated_otps_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/lists_providers/paginated_notes_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_action_modal.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/lists/empty_list.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/lists/passwords_list.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/lists/otps_list.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/lists/notes_list.dart';
import 'package:hoplixi/features/password_manager/dashboard/futures/otp_form/otp_edit_modal.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:flutter/scheduler.dart';

const double _kScrollThreshold = 200.0; // Порог для пагинации при скролле

/// Виджет для отображения списков различных сущностей с пагинацией
class EntityListView extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const EntityListView({super.key, this.scrollController});

  @override
  ConsumerState<EntityListView> createState() => _EntityListViewState();
}

class _EntityListViewState extends ConsumerState<EntityListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) _scrollController.dispose();

    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - _kScrollThreshold) {
      final entityType = ref.read(currentEntityTypeProvider);

      switch (entityType) {
        case EntityType.password:
          ref.read(paginatedPasswordsProvider.notifier).loadMore();
          break;
        case EntityType.otp:
          ref.read(paginatedOtpsProvider.notifier).loadMore();
          break;
        case EntityType.note:
          ref.read(paginatedNotesProvider.notifier).loadMore();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entityType = ref.watch(currentEntityTypeProvider);

    logDebug('Текущий тип сущности: $entityType', tag: 'EntityListView');

    switch (entityType) {
      case EntityType.password:
        return _buildPasswordsList();
      case EntityType.otp:
        return _buildOtpsList();
      case EntityType.note:
        return _buildNotesList();
    }
  }

  Widget _buildPasswordsList() {
    final passwordsAsync = ref.watch(paginatedPasswordsProvider);

    return passwordsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка данных...'),
            ],
          ),
        ),
      ),
      error: (error, _) => _ErrorSliverView(
        error: error.toString(),
        onRetry: () {
          ref.read(paginatedPasswordsProvider.notifier).refresh();
        },
      ),
      data: (state) {
        if (state.passwords.isEmpty && !state.isLoading) {
          return SliverFillRemaining(
            child: EmptyView(
              title: 'Нет паролей',
              subtitle: 'Создайте первый пароль, чтобы начать работу',
              icon: Icons.password,
            ),
          );
        }

        return SliverStack(
          children: [
            PasswordsSliverList(
              state: state,
              scrollController: _scrollController,
              onPasswordFavoriteToggle: _onPasswordFavoriteToggle,
              onPasswordEdit: _onPasswordEdit,
              onPasswordDelete: _onPasswordDelete,
              onPasswordLongPress: _onPasswordLongPress,
            ),
            if (state.isLoading)
              SliverFillRemaining(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOtpsList() {
    final otpsAsync = ref.watch(paginatedOtpsProvider);

    return otpsAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка данных...'),
            ],
          ),
        ),
      ),
      error: (error, _) => _ErrorSliverView(
        error: error.toString(),
        onRetry: () {
          ref.read(paginatedOtpsProvider.notifier).refresh();
        },
      ),
      data: (state) {
        if (state.otps.isEmpty && !state.isLoading) {
          return SliverFillRemaining(
            child: EmptyView(
              title: 'Нет OTP',
              subtitle: 'Создайте первый OTP, чтобы начать работу',
              icon: Icons.security,
            ),
          );
        }

        return SliverStack(
          children: [
            OtpsSliverList(
              state: state,
              scrollController: _scrollController,
              onOtpFavoriteToggle: _onOtpFavoriteToggle,
              onOtpEdit: _onOtpEdit,
              onOtpDelete: _onOtpDelete,
              onOtpLongPress: _onOtpLongPress,
            ),
            if (state.isLoading)
              SliverFillRemaining(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotesList() {
    final notesAsync = ref.watch(paginatedNotesProvider);

    return notesAsync.when(
      loading: () => const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка данных...'),
            ],
          ),
        ),
      ),
      error: (error, _) => _ErrorSliverView(
        error: error.toString(),
        onRetry: () {
          ref.read(paginatedNotesProvider.notifier).refresh();
        },
      ),
      data: (state) {
        if (state.notes.isEmpty && !state.isLoading) {
          return SliverFillRemaining(
            child: EmptyView(
              title: 'Нет заметок',
              subtitle: 'Создайте первую заметку, чтобы начать работу',
              icon: Icons.note,
            ),
          );
        }

        return SliverStack(
          children: [
            NotesSliverList(
              state: state,
              scrollController: _scrollController,
              onNoteFavoriteToggle: _onNoteFavoriteToggle,
              onNotePinToggle: _onNotePinToggle,
              onNoteEdit: _onNoteEdit,
              onNoteDelete: _onNoteDelete,
              onNoteLongPress: _onNoteLongPress,
            ),
            if (state.isLoading)
              SliverFillRemaining(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onPasswordFavoriteToggle(CardPasswordDto password) {
    logInfo(
      'EntityListView: Переключение избранного для пароля ${password.id}',
    );
    if (mounted) {
      ref.read(paginatedPasswordsProvider.notifier).toggleFavorite(password.id);
    }
  }

  void _onPasswordEdit(CardPasswordDto password) {
    logInfo('EntityListView: Редактирование пароля ${password.id}');
    context.push('${AppRoutes.passwordForm}/${password.id}');
  }

  void _onPasswordDelete(CardPasswordDto password) {
    logInfo('EntityListView: Удаление пароля ${password.id}');
    if (mounted) {
      ref.read(paginatedPasswordsProvider.notifier).deletePassword(password.id);
    }
  }

  void _onPasswordLongPress(CardPasswordDto password) {
    logInfo('EntityListView: Долгое нажатие на пароль ${password.id}');
    EntityActionModalHelper.showPasswordActions(
      context,
      passwordName: password.name,
      loginOrEmail: password.login ?? password.email ?? 'Нет данных',
      onEdit: () => _onPasswordEdit(password),
      onDelete: () => _onPasswordDelete(password),
    );
  }

  void _onOtpFavoriteToggle(CardOtpDto otp) {
    logInfo('EntityListView: Переключение избранного для OTP ${otp.id}');
    if (mounted) {
      ref.read(paginatedOtpsProvider.notifier).toggleFavorite(otp.id);
    }
  }

  void _onOtpEdit(CardOtpDto otp) async {
    logInfo('EntityListView: Редактирование OTP ${otp.id}');

    final result = await OtpEditModalHelper.show(context, otp);

    // Если изменения были сохранены, обновляем список в следующем кадре
    if (result == true && mounted) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(paginatedOtpsProvider.notifier).refresh();
        }
      });
    }
  }

  void _onOtpDelete(CardOtpDto otp) {
    logInfo('EntityListView: Удаление OTP ${otp.id}');
    if (mounted) {
      ref.read(paginatedOtpsProvider.notifier).deleteOtp(otp.id);
    }
  }

  void _onOtpLongPress(CardOtpDto otp) {
    logInfo('EntityListView: Долгое нажатие на OTP ${otp.id}');
    EntityActionModalHelper.showOtpActions(
      context,
      issuer: otp.issuer ?? 'Unknown',
      accountName: otp.accountName ?? 'Нет данных',
      onEdit: () => _onOtpEdit(otp),
      onDelete: () => _onOtpDelete(otp),
    );
  }

  void _onNoteFavoriteToggle(CardNoteDto note) {
    logInfo('EntityListView: Переключение избранного для заметки ${note.id}');
    if (mounted) {
      ref.read(paginatedNotesProvider.notifier).toggleFavorite(note.id);
    }
  }

  void _onNotePinToggle(CardNoteDto note) {
    logInfo('EntityListView: Переключение закрепления для заметки ${note.id}');
    if (mounted) {
      ref.read(paginatedNotesProvider.notifier).togglePinned(note.id);
    }
  }

  void _onNoteEdit(CardNoteDto note) {
    logInfo('EntityListView: Редактирование заметки ${note.id}');
    context.push('${AppRoutes.notesForm}/${note.id}');
  }

  void _onNoteDelete(CardNoteDto note) {
    logInfo('EntityListView: Удаление заметки ${note.id}');
    if (mounted) {
      ref.read(paginatedNotesProvider.notifier).deleteNote(note.id);
    }
  }

  void _onNoteLongPress(CardNoteDto note) {
    logInfo('EntityListView: Долгое нажатие на заметку ${note.id}');
    EntityActionModalHelper.showNoteActions(
      context,
      noteTitle: note.title,
      noteContent: note.content ?? note.description ?? 'Нет содержимого',
      onEdit: () => _onNoteEdit(note),
      onDelete: () => _onNoteDelete(note),
    );
  }
}

/// Виджет ошибки как Sliver
class _ErrorSliverView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _ErrorSliverView({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Произошла ошибка',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SmoothButton(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: 'Повторить',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
