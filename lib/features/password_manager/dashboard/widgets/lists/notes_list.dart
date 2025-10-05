import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/lists_providers/paginated_notes_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/note_card.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

/// Виджет списка заметок как Sliver
class NotesSliverList extends StatelessWidget {
  final PaginatedNotesState state;
  final ScrollController? scrollController;
  final Function(CardNoteDto) onNoteFavoriteToggle;
  final Function(CardNoteDto) onNotePinToggle;
  final Function(CardNoteDto) onNoteEdit;
  final Function(CardNoteDto) onNoteDelete;
  final Function(CardNoteDto) onNoteLongPress;

  const NotesSliverList({
    super.key,
    required this.state,
    this.scrollController,
    required this.onNoteFavoriteToggle,
    required this.onNotePinToggle,
    required this.onNoteEdit,
    required this.onNoteDelete,
    required this.onNoteLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Обработка индикатора загрузки
          if (index == state.notes.length) {
            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (!state.hasMore) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Все заметки загружены (${state.totalCount})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final note = state.notes[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              index == 0 ? 16 : 8,
              8,
              index == state.notes.length - 1 && !state.hasMore ? 16 : 8,
            ),
            child: NoteCard(
              note: note,
              onFavoriteToggle: () => onNoteFavoriteToggle(note),
              onPinToggle: () => onNotePinToggle(note),
              onEdit: () => onNoteEdit(note),
              onDelete: () => onNoteDelete(note),
              onLongPress: () => onNoteLongPress(note),
            ),
          );
        },
        childCount:
            state.notes.length +
            (state.isLoadingMore || !state.hasMore ? 1 : 0),
      ),
    );
  }
}
