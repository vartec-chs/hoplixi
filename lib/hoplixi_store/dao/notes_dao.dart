import 'package:drift/drift.dart';
import 'package:hoplixi/hoplixi_store/utils/uuid_generator.dart';
import '../hoplixi_store.dart';
import '../tables/notes.dart';
import '../dto/db_dto.dart';

part 'notes_dao.g.dart';

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<HoplixiStore> with _$NotesDaoMixin {
  NotesDao(super.db);

  /// Создание новой заметки
  Future<String> createNote(CreateNoteDto dto) async {
    final id = UuidGenerator.generate();
    final companion = NotesCompanion(
      id: Value(id),
      title: Value(dto.title),
      description: Value(dto.description),
      deltaJson: Value(dto.deltaJson),
      content: Value(dto.content),
      categoryId: Value(dto.categoryId),
      isFavorite: Value(dto.isFavorite),
      isPinned: Value(dto.isPinned),
    );

    await into(
      attachedDatabase.notes,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return companion.id.value;
  }

  /// Обновление заметки
  Future<bool> updateNote(UpdateNoteDto dto) async {
    final companion = NotesCompanion(
      id: Value(dto.id),
      title: dto.title != null ? Value(dto.title!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      deltaJson: dto.deltaJson != null
          ? Value(dto.deltaJson!)
          : const Value.absent(),
      content: dto.content != null ? Value(dto.content!) : const Value.absent(),
      categoryId: dto.categoryId != null
          ? Value(dto.categoryId)
          : const Value.absent(),
      isFavorite: dto.isFavorite != null
          ? Value(dto.isFavorite!)
          : const Value.absent(),
      isPinned: dto.isPinned != null
          ? Value(dto.isPinned!)
          : const Value.absent(),
      lastAccessed: dto.lastAccessed != null
          ? Value(dto.lastAccessed)
          : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(
      attachedDatabase.notes,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление заметки по ID
  Future<bool> deleteNote(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.notes,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение заметки по ID
  Future<Note?> getNoteById(String id) async {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех заметок
  Future<List<Note>> getAllNotes() async {
    final query = select(attachedDatabase.notes)
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.modifiedAt),
      ]);
    return await query.get();
  }

  /// Получение заметок по категории
  Future<List<Note>> getNotesByCategory(String categoryId) async {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.modifiedAt),
      ]);
    return await query.get();
  }

  /// Получение избранных заметок
  Future<List<Note>> getFavoriteNotes() async {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.modifiedAt),
      ]);
    return await query.get();
  }

  /// Получение закрепленных заметок
  Future<List<Note>> getPinnedNotes() async {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.isPinned.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Поиск заметок по заголовку или содержимому
  Future<List<Note>> searchNotes(String searchTerm) async {
    final query = select(attachedDatabase.notes)
      ..where(
        (tbl) =>
            tbl.title.like('%$searchTerm%') |
            tbl.content.like('%$searchTerm%') |
            tbl.description.like('%$searchTerm%'),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.modifiedAt),
      ]);
    return await query.get();
  }

  /// Получение недавно просмотренных заметок
  Future<List<Note>> getRecentlyAccessedNotes({int limit = 10}) async {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.lastAccessed.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastAccessed)])
      ..limit(limit);
    return await query.get();
  }

  /// Обновление времени последнего доступа
  Future<void> updateLastAccessed(String id) async {
    await (update(
      attachedDatabase.notes,
    )..where((tbl) => tbl.id.equals(id))).write(
      NotesCompanion(
        lastAccessed: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Закрепление/открепление заметки
  Future<void> togglePinNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await (update(
        attachedDatabase.notes,
      )..where((tbl) => tbl.id.equals(id))).write(
        NotesCompanion(
          isPinned: Value(!note.isPinned),
          modifiedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Добавление/удаление из избранного
  Future<void> toggleFavoriteNote(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      await (update(
        attachedDatabase.notes,
      )..where((tbl) => tbl.id.equals(id))).write(
        NotesCompanion(
          isFavorite: Value(!note.isFavorite),
          modifiedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Получение количества заметок
  Future<int> getNotesCount() async {
    final query = selectOnly(attachedDatabase.notes)
      ..addColumns([attachedDatabase.notes.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.notes.id.count()) ?? 0;
  }

  /// Получение количества заметок по категориям
  Future<Map<String?, int>> getNotesCountByCategory() async {
    final query = selectOnly(attachedDatabase.notes)
      ..addColumns([
        attachedDatabase.notes.categoryId,
        attachedDatabase.notes.id.count(),
      ])
      ..groupBy([attachedDatabase.notes.categoryId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.notes.categoryId):
            row.read(attachedDatabase.notes.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми заметками
  Stream<List<Note>> watchAllNotes() {
    final query = select(attachedDatabase.notes)
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.modifiedAt),
      ]);
    return query.watch();
  }

  /// Stream для наблюдения за заметками по категории
  Stream<List<Note>> watchNotesByCategory(String categoryId) {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.modifiedAt),
      ]);
    return query.watch();
  }

  /// Stream для наблюдения за избранными заметками
  Stream<List<Note>> watchFavoriteNotes() {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isPinned),
        (t) => OrderingTerm.desc(t.modifiedAt),
      ]);
    return query.watch();
  }

  /// Stream для наблюдения за закрепленными заметками
  Stream<List<Note>> watchPinnedNotes() {
    final query = select(attachedDatabase.notes)
      ..where((tbl) => tbl.isPinned.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Batch операции для создания множественных заметок
  Future<void> createNotesBatch(List<CreateNoteDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = NotesCompanion(
          title: Value(dto.title),
          description: Value(dto.description),
          deltaJson: Value(dto.deltaJson),
          content: Value(dto.content),
          categoryId: Value(dto.categoryId),
          isFavorite: Value(dto.isFavorite),
          isPinned: Value(dto.isPinned),
        );
        batch.insert(attachedDatabase.notes, companion);
      }
    });
  }
}
