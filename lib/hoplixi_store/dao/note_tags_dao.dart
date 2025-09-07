import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/note_tags.dart';
import '../tables/notes.dart';
import '../tables/tags.dart';

part 'note_tags_dao.g.dart';

@DriftAccessor(tables: [NoteTags, Notes, Tags])
class NoteTagsDao extends DatabaseAccessor<HoplixiStore>
    with _$NoteTagsDaoMixin {
  NoteTagsDao(HoplixiStore db) : super(db);

  /// Добавление тега к заметке
  Future<void> addTagToNote(String noteId, String tagId) async {
    final companion = NoteTagsCompanion(
      noteId: Value(noteId),
      tagId: Value(tagId),
    );

    await into(
      attachedDatabase.noteTags,
    ).insert(companion, mode: InsertMode.insertOrIgnore);
  }

  /// Удаление тега у заметки
  Future<bool> removeTagFromNote(String noteId, String tagId) async {
    final rowsAffected =
        await (delete(attachedDatabase.noteTags)..where(
              (tbl) => tbl.noteId.equals(noteId) & tbl.tagId.equals(tagId),
            ))
            .go();
    return rowsAffected > 0;
  }

  /// Получение всех тегов для заметки
  Future<List<Tag>> getTagsForNote(String noteId) async {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.noteTags,
        attachedDatabase.noteTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.noteTags.noteId.equals(noteId));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.tags)).toList();
  }

  /// Получение всех заметок для тега
  Future<List<Note>> getNotesForTag(String tagId) async {
    final query = select(attachedDatabase.notes).join([
      innerJoin(
        attachedDatabase.noteTags,
        attachedDatabase.noteTags.noteId.equalsExp(attachedDatabase.notes.id),
      ),
    ])..where(attachedDatabase.noteTags.tagId.equals(tagId));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.notes)).toList();
  }

  /// Получение заметок с тегами
  Future<List<NoteWithTags>> getNotesWithTags() async {
    final notesQuery = select(attachedDatabase.notes);
    final notes = await notesQuery.get();

    final List<NoteWithTags> result = [];

    for (final note in notes) {
      final tags = await getTagsForNote(note.id);
      result.add(NoteWithTags(note: note, tags: tags));
    }

    return result;
  }

  /// Получение заметок по множественным тегам (AND условие)
  Future<List<Note>> getNotesByTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    String placeholders = tagIds.map((_) => '?').join(',');

    final query = customSelect(
      '''
      SELECT n.* FROM notes n
      WHERE n.id IN (
        SELECT nt.note_id
        FROM note_tags nt
        WHERE nt.tag_id IN ($placeholders)
        GROUP BY nt.note_id
        HAVING COUNT(DISTINCT nt.tag_id) = ?
      )
      ORDER BY n.is_pinned DESC, n.modified_at DESC
    ''',
      variables: [...tagIds.map((id) => Variable(id)), Variable(tagIds.length)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => Note(
            id: row.read<String>('id'),
            title: row.read<String>('title'),
            description: row.read<String?>('description'),
            content: row.read<String>('content'),
            categoryId: row.read<String?>('category_id'),
            isFavorite: row.read<bool>('is_favorite'),
            isPinned: row.read<bool>('is_pinned'),
            createdAt: row.read<DateTime>('created_at'),
            modifiedAt: row.read<DateTime>('modified_at'),
            lastAccessed: row.read<DateTime?>('last_accessed'),
          ),
        )
        .toList();
  }

  /// Получение заметок по любому из тегов (OR условие)
  Future<List<Note>> getNotesByAnyTag(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    final query = select(attachedDatabase.notes).join([
      innerJoin(
        attachedDatabase.noteTags,
        attachedDatabase.noteTags.noteId.equalsExp(attachedDatabase.notes.id),
      ),
    ])..where(attachedDatabase.noteTags.tagId.isIn(tagIds));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.notes)).toList();
  }

  /// Замена всех тегов у заметки
  Future<void> replaceNoteTags(String noteId, List<String> tagIds) async {
    await transaction(() async {
      // Удаляем все существующие теги
      await (delete(
        attachedDatabase.noteTags,
      )..where((tbl) => tbl.noteId.equals(noteId))).go();

      // Добавляем новые теги
      for (final tagId in tagIds) {
        await addTagToNote(noteId, tagId);
      }
    });
  }

  /// Проверка наличия тега у заметки
  Future<bool> noteHasTag(String noteId, String tagId) async {
    final query = select(attachedDatabase.noteTags)
      ..where((tbl) => tbl.noteId.equals(noteId) & tbl.tagId.equals(tagId));

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества заметок для каждого тега
  Future<Map<String, int>> getNoteCountPerTag() async {
    final query = selectOnly(attachedDatabase.noteTags)
      ..addColumns([
        attachedDatabase.noteTags.tagId,
        attachedDatabase.noteTags.noteId.count(),
      ])
      ..groupBy([attachedDatabase.noteTags.tagId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.noteTags.tagId)!:
            row.read(attachedDatabase.noteTags.noteId.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за тегами заметки
  Stream<List<Tag>> watchTagsForNote(String noteId) {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.noteTags,
        attachedDatabase.noteTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.noteTags.noteId.equals(noteId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.tags)).toList(),
    );
  }

  /// Stream для наблюдения за заметками тега
  Stream<List<Note>> watchNotesForTag(String tagId) {
    final query = select(attachedDatabase.notes).join([
      innerJoin(
        attachedDatabase.noteTags,
        attachedDatabase.noteTags.noteId.equalsExp(attachedDatabase.notes.id),
      ),
    ])..where(attachedDatabase.noteTags.tagId.equals(tagId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.notes)).toList(),
    );
  }

  /// Batch операции для множественного добавления тегов
  Future<void> addTagsToNotesBatch(
    List<String> noteIds,
    List<String> tagIds,
  ) async {
    await batch((batch) {
      for (final noteId in noteIds) {
        for (final tagId in tagIds) {
          final companion = NoteTagsCompanion(
            noteId: Value(noteId),
            tagId: Value(tagId),
          );
          batch.insert(
            attachedDatabase.noteTags,
            companion,
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  /// Очистка всех связей для удаленных заметок или тегов
  Future<int> cleanupOrphanedRelations() async {
    final deletedCount = await customUpdate('''
      DELETE FROM note_tags
      WHERE note_id NOT IN (SELECT id FROM notes)
         OR tag_id NOT IN (SELECT id FROM tags)
    ''');

    return deletedCount;
  }
}

/// Класс для заметки с тегами
class NoteWithTags {
  final Note note;
  final List<Tag> tags;

  NoteWithTags({required this.note, required this.tags});
}
