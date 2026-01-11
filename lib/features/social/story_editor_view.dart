import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'comments_controller.dart';

class StoryEditorView extends StatefulWidget {
  final String? editingCommentId;
  final String? initialContent;

  const StoryEditorView({
    super.key,
    this.editingCommentId,
    this.initialContent,
  });

  @override
  State<StoryEditorView> createState() => _StoryEditorViewState();
}

class _StoryEditorViewState extends State<StoryEditorView> {
  final CommentsController controller = Get.find<CommentsController>();
  late QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool isUploading = false;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _initQuillController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _initQuillController() {
    try {
      String content = widget.initialContent ?? "";
      if (content.isEmpty) {
        _quillController = QuillController.basic();
      } else {
        // Parse Markdown to Delta
        final delta = _parseMarkdownToDelta(content);

        // Ensure ends with newline
        if (delta.last.data is String &&
            !(delta.last.data as String).endsWith('\n')) {
          delta.insert('\n');
        }

        _quillController = QuillController(
          document: Document.fromDelta(delta),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
      print("Quill Init Error: $e");
      _initError = true;
      _quillController = QuillController.basic();
    }
  }

  // Simple Markdown Parser (Regex-based)
  // Supports: Bold (**), Italic (*), and Images (![])
  Delta _parseMarkdownToDelta(String markdown) {
    final delta = Delta();
    final lines = markdown.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Checklist: Image?
      // Pattern: ![Alt](url)
      final imageRegExp = RegExp(r'!\[(.*?)\]\((.*?)\)');
      final imageMatch = imageRegExp.firstMatch(line);

      if (imageMatch != null) {
        final imageUrl = imageMatch.group(2);
        if (imageUrl != null) {
          delta.insert({'image': imageUrl});
          delta.insert('\n'); // Image needs its own block usually
          continue;
        }
      }

      // Process Text Line
      // We will scan the line for **bold** and *italic*
      // This is a greedy, simple parser.

      int currentIndex = 0;

      // Find all potential matches
      // Group 1: **bold** (inner: Group 2)
      // Group 3: *italic* (inner: Group 4)
      final styleRegExp = RegExp(r'(\*\*(.*?)\*\*)|(\*(.*?)\*)');
      final matches = styleRegExp.allMatches(line);

      for (final match in matches) {
        // Text before match
        if (match.start > currentIndex) {
          delta.insert(line.substring(currentIndex, match.start));
        }

        // Bold
        if (match.group(1) != null) {
          delta.insert(match.group(2)!, {'bold': true});
        }
        // Italic
        else if (match.group(3) != null) {
          delta.insert(match.group(4)!, {'italic': true});
        }

        currentIndex = match.end;
      }

      // Remaining text
      if (currentIndex < line.length) {
        delta.insert(line.substring(currentIndex));
      }

      // Add newline unless it's strictly the end and we want to control it,
      // but typically lines imply newlines.
      delta.insert('\n');
    }

    return delta;
  }

  @override
  void dispose() {
    _quillController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => isUploading = true);

        final bytes = await image.readAsBytes();
        final name = image.name;
        final ext = name.contains('.') ? name.split('.').last : 'jpg';

        final url = await controller.uploadImage(bytes, ext);

        setState(() => isUploading = false);

        if (url != null) {
          final index = _quillController.selection.baseOffset;
          final length = _quillController.selection.extentOffset - index;
          _quillController.replaceText(
            index,
            length,
            BlockEmbed.image(url),
            null,
          );
          _quillController.moveCursorToPosition(index + 1);
        }
      }
    } catch (e) {
      if (mounted) setState(() => isUploading = false);
      Get.snackbar("Error", "Could not pick image");
    }
  }

  void _handlePost() {
    final delta = _quillController.document.toDelta();
    final buffer = StringBuffer();
    for (final op in delta.toList()) {
      if (op.data is String) {
        String text = op.data as String;

        // Simplify: don't double-escape if already valid?
        // But here we are converting FROM Delta (rich text) TO Markdown string.

        if (op.attributes != null) {
          if (op.attributes!.containsKey('bold')) {
            if (text.trim().isNotEmpty) {
              text = "**$text**";
            }
          } else if (op.attributes!.containsKey('italic')) {
            if (text.trim().isNotEmpty) {
              text = "*$text*";
            }
          }
          if (op.attributes!.containsKey('header')) {
            text = "## $text";
          }
        }
        buffer.write(text);
      } else if (op.data is Map) {
        final map = op.data as Map;
        if (map.containsKey('image')) {
          buffer.write("\n![image](${map['image']})\n");
        }
      }
    }
    final markdown = buffer.toString();

    if (markdown.trim().isNotEmpty) {
      if (widget.editingCommentId != null) {
        controller.updateComment(widget.editingCommentId!, markdown);
      } else {
        controller.postComment(markdown);
      }
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.black54),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.editingCommentId != null ? "编辑故事" : "撰写故事",
          style: GoogleFonts.outfit(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isUploading ? null : _pickImage,
            icon: isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.image_outlined, color: Colors.black87),
            tooltip: "插入图片",
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: (controller.isPosting.value || isUploading)
                      ? null
                      : _handlePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 0,
                    ),
                  ),
                  child: controller.isPosting.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.editingCommentId != null ? "更新" : "发布"),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1),

          if (_initError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.amber[100],
              child: const Text("初始化编辑器时发生错误，已重置为空白状态。"),
            ),

          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showSearchButton: false,
              showSubscript: false,
              showSuperscript: false,
            ),
          ),

          if (isUploading)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),

          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: QuillEditor(
                controller: _quillController,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: QuillEditorConfig(
                  placeholder: "写下你的故事...",
                  autoFocus: true,
                  expands: false,
                  scrollable: true,
                  padding: EdgeInsets.zero,
                  showCursor: true,
                  minHeight: 300,
                  embedBuilders: [ImageEmbedBuilder()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'image';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    String imageUrl = "";
    if (embedContext.node.value.data is String) {
      imageUrl = embedContext.node.value.data as String;
    }

    if (imageUrl.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                const SizedBox(height: 8),
                Text(
                  "图片加载失败",
                  style: GoogleFonts.outfit(color: Colors.grey[600]),
                ),
                Text(
                  "$error",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[100],
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      ),
    );
  }
}
