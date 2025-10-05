import 'dart:convert';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

import 'note_metadata_dialog.dart';
import 'time_stamp_embed.dart';
import 'toolbar.dart';
import 'youtube_video_player.dart';

/// Экран создания и редактирования заметок

class NotesFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const NotesFormScreen({super.key, this.id});

  @override
  ConsumerState<NotesFormScreen> createState() => _NotesFormScreenState();
}

class _NotesFormScreenState extends ConsumerState<NotesFormScreen> {
  static const String _logTag = 'NotesForm';

  late final QuillController _controller;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  // Метаданные заметки
  NoteMetadata? _metadata;
  bool _isSaving = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: true,
          onImagePaste: (imageBytes) async {
            if (kIsWeb) {
              // Dart IO is unsupported on the web.
              return null;
            }
            // Save the image somewhere and return the image URL that will be
            // stored in the Quill Delta JSON (the document).
            final newFileName =
                'image-file-${DateTime.now().toIso8601String()}.png';
            final newPath = path.join(
              io.Directory.systemTemp.path,
              newFileName,
            );
            logInfo('Pasting image to $newPath', tag: _logTag);
            final file = await io.File(
              newPath,
            ).writeAsBytes(imageBytes, flush: true);
            return file.path;
          },
        ),
      ),
    );

    // Загружаем заметку если редактируем
    if (widget.id != null) {
      _loadNote();
    } else {
      // Для новой заметки загружаем пустой документ
      _controller.document = Document.fromJson(
        jsonDecode('[{"insert":"\\n"}]'),
      );
    }
  }

  /// Загружает заметку для редактирования
  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(notesServiceProvider);
      final result = await service.getNoteWithFullDetails(widget.id!);

      if (!result.success || result.data == null) {
        if (mounted) {
          ToastHelper.error(
            title: 'Ошибка',
            description: result.message ?? 'Не удалось загрузить заметку',
          );
          context.pop();
        }
        return;
      }

      final details = result.data!;
      final note = details.note;

      // Загружаем контент в редактор
      try {
        _controller.document = Document.fromJson(jsonDecode(note.deltaJson));
      } catch (e) {
        logError('Ошибка загрузки deltaJson', error: e, tag: _logTag);
        // Если не удалось загрузить deltaJson, используем content
        _controller.document = Document()..insert(0, note.content);
      }

      // Загружаем метаданные
      setState(() {
        _metadata = NoteMetadata(
          title: note.title,
          description: note.description,
          categoryId: note.categoryId,
          tagIds: details.tags.map((tag) => tag.id).toList(),
        );
      });
    } catch (e, stackTrace) {
      logError(
        'Ошибка загрузки заметки',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Не удалось загрузить заметку: $e',
        );
        context.pop();
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Открывает диалог метаданных и сохраняет заметку
  Future<void> _onSave() async {
    // Показываем диалог метаданных
    final metadata = await showNoteMetadataDialog(
      context,
      initialMetadata: _metadata,
      isEditing: widget.id != null,
    );

    if (metadata == null) return; // Пользователь отменил

    setState(() {
      _isSaving = true;
    });

    try {
      final service = ref.read(notesServiceProvider);

      // Получаем содержимое из редактора
      final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
      final plainText = _controller.document.toPlainText();

      if (widget.id == null) {
        // Создание новой заметки
        final createDto = CreateNoteDto(
          title: metadata.title,
          description: metadata.description,
          deltaJson: deltaJson,
          content: plainText,
          categoryId: metadata.categoryId,
          isFavorite: false,
          isPinned: false,
        );

        final result = await service.createNote(
          createDto,
          tagIds: metadata.tagIds.isNotEmpty ? metadata.tagIds : null,
        );

        if (result.success) {
          if (mounted) {
            DataRefreshHelper.refreshNotes(ref);
            ToastHelper.success(
              title: 'Успех',
              description: result.message ?? 'Заметка создана',
            );
            context.pop();
          }
        } else {
          if (mounted) {
            ToastHelper.error(
              title: 'Ошибка',
              description: result.message ?? 'Не удалось создать заметку',
            );
          }
        }
      } else {
        // Обновление существующей заметки
        final updateDto = UpdateNoteDto(
          id: widget.id!,
          title: metadata.title,
          description: metadata.description,
          deltaJson: deltaJson,
          content: plainText,
          categoryId: metadata.categoryId,
        );

        final result = await service.updateNote(
          updateDto,
          tagIds: metadata.tagIds.isNotEmpty ? metadata.tagIds : null,
          replaceAllTags: true, // Заменяем все теги
        );

        if (result.success) {
          if (mounted) {
            DataRefreshHelper.refreshNotes(ref);

            ToastHelper.success(
              title: 'Успех',
              description: result.message ?? 'Заметка обновлена',
            );
            setState(() {
              _metadata = metadata;
            });
          }
        } else {
          if (mounted) {
            ToastHelper.error(
              title: 'Ошибка',
              description: result.message ?? 'Не удалось обновить заметку',
            );
          }
        }
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка сохранения заметки',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
      );
      if (mounted) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'Не удалось сохранить заметку: $e',
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Загрузка...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(widget.id == null ? 'Новая заметка' : 'Редактор заметок'),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          IconButton(
            tooltip: 'Сохранить',
            onPressed: _isSaving ? null : _onSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Toolbar(controller: _controller),
        ),
      ),
      body: SafeArea(
        child: QuillEditor(
          focusNode: _editorFocusNode,
          scrollController: _editorScrollController,
          controller: _controller,
          config: QuillEditorConfig(
            placeholder: 'Начните вводить текст...',
            padding: const EdgeInsets.all(16),
            embedBuilders: [
              ...FlutterQuillEmbeds.editorBuilders(
                imageEmbedConfig: QuillEditorImageEmbedConfig(
                  imageProviderBuilder: (context, imageUrl) {
                    logDebug('Loading embedded image: $imageUrl', tag: _logTag);
                    // TODO: В будущем здесь будет обработка вложений
                    return null;
                  },
                  onImageRemovedCallback: (imageUrl) async {
                    logInfo('Image removed: $imageUrl', tag: _logTag);
                  },
                ),
                videoEmbedConfig: QuillEditorVideoEmbedConfig(
                  customVideoBuilder: (videoUrl, readOnly) {
                    logDebug('Loading embedded video: $videoUrl', tag: _logTag);

                    // if (_isYouTubeUrl(videoUrl) &&
                    //     !(UniversalPlatform.isLinux)) {
                    //   return YoutubeVideoPlayer(videoUrl: videoUrl);
                    // }
                    return null;
                  },
                ),
              ),
              TimeStampEmbedBuilder(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }
}

bool _isYouTubeUrl(String videoUrl) {
  try {
    final uri = Uri.parse(videoUrl);
    return uri.host == 'www.youtube.com' ||
        uri.host == 'youtube.com' ||
        uri.host == 'youtu.be' ||
        uri.host == 'www.youtu.be';
  } catch (_) {
    return false;
  }
}
