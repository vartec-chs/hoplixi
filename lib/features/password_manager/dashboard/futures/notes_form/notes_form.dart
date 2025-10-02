import 'dart:convert';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';

import 'time_stamp_embed.dart';
import 'toolbar.dart';
import 'youtube_video_player.dart';

class NotesFormScreen extends StatefulWidget {
  const NotesFormScreen({super.key});

  @override
  State<NotesFormScreen> createState() => _NotesFormScreenState();
}

class _NotesFormScreenState extends State<NotesFormScreen> {
  static const String _logTag = 'NotesForm';
  final QuillController _controller = () {
    return QuillController.basic(
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
  }();
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load document
    _controller.document = Document.fromJson(
      jsonDecode('[{"insert":"Написать!\\n"}]'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('Редактор заметок'),
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          IconButton(
            tooltip: 'Сохранить',
            onPressed: () {
              // Save document
              final deltaJson = jsonEncode(
                _controller.document.toDelta().toJson(),
              );
              logInfo('Document saved: $deltaJson', tag: _logTag);
              // context.pop();
            },
            icon: const Icon(Icons.save_rounded),
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
                    // https://pub.dev/packages/flutter_quill_extensions#-image-assets
                    if (imageUrl.startsWith('assets/')) {
                      return AssetImage(imageUrl);
                    }
                    return null;
                  },
                  onImageRemovedCallback: (imageUrl) async {
                    logInfo('Image removed: $imageUrl', tag: _logTag);
                  },
                ),
                videoEmbedConfig: QuillEditorVideoEmbedConfig(
                  customVideoBuilder: (videoUrl, readOnly) {
                    logDebug('Loading embedded video: $videoUrl', tag: _logTag);
                    // Example: Check for YouTube Video URL and return your
                    // YouTube video widget here.

                    // Note: YouTube videos are not supported on Linux due to platform limitations
                    if (_isYouTubeUrl(videoUrl) &&
                        !(UniversalPlatform.isLinux)) {
                      return YoutubeVideoPlayer(videoUrl: videoUrl);
                    }

                    // Return null to fallback to the default logic
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
