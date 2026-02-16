import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node; // Fix Node conflict
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import '../../core/widgets/common_dialog.dart';
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
  Node? _selectedImageNode;

  @override
  void initState() {
    super.initState();
    _initQuillController();

    // Listen for selection changes
    _quillController.addListener(_onSelectionChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _onSelectionChanged() {
    final selection = _quillController.selection;

    // Auto-detect image selection if cursor is on an image
    if (selection.isCollapsed) {
      final child = _quillController.document.queryChild(selection.baseOffset);
      Node? node = child.node;

      // Drill down if it's a Line (Container) to find the leaf (Embed/Text)
      if (node is Line) {
        final leafResult = node.queryChild(child.offset, false);
        node = leafResult.node;
      }

      if (node != null && node is Embed && node.value.type == 'image') {
        if (_selectedImageNode != node) {
          if (mounted) setState(() => _selectedImageNode = node);
        }
        return;
      }
    }

    // Deselect if moved away
    if (_selectedImageNode != null) {
      final nodeOffset = _selectedImageNode!.documentOffset;
      if (selection.baseOffset < nodeOffset ||
          selection.baseOffset > nodeOffset + 1) {
        if (mounted) setState(() => _selectedImageNode = null);
      }
    }
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

      // Fix: Skip trailing empty line if it's the result of the last newline split
      // But keep empty lines that are intentional newlines between paragraphs
      if (i == lines.length - 1 && line.isEmpty) {
        continue;
      }

      // Checklist: Image?
      // Pattern: ![Alt](url)
      final imageRegExp = RegExp(r'!\[(.*?)\]\((.*?)\)');
      final imageMatch = imageRegExp.firstMatch(line);

      if (imageMatch != null) {
        String imageUrl = imageMatch.group(2) ?? "";
        final attributes = <String, dynamic>{};

        // Parse attributes from URL query params
        if (imageUrl.contains('?')) {
          final uri = Uri.parse(imageUrl);
          final query = Map<String, String>.from(uri.queryParameters);

          if (query.containsKey('q_w')) {
            attributes['width'] = query['q_w'];
            // Also set 'style' for extensions compatibility
            attributes['style'] = 'width: ${query['q_w']}px;';
            query.remove('q_w');
          }
          if (query.containsKey('q_h')) {
            attributes['height'] = query['q_h'];
            if (attributes.containsKey('style')) {
              attributes['style'] += ' height: ${query['q_h']}px;';
            } else {
              attributes['style'] = 'height: ${query['q_h']}px;';
            }
            query.remove('q_h');
          }
          if (query.containsKey('q_a')) {
            attributes['align'] = query['q_a'];
            query.remove('q_a');
          }

          // Clean URL (remove our custom params)
          if (query.isEmpty) {
            imageUrl = uri.replace(query: null).toString();
            if (imageUrl.endsWith('?'))
              imageUrl = imageUrl.substring(0, imageUrl.length - 1);
          } else {
            imageUrl = uri.replace(queryParameters: query).toString();
          }
        }

        if (imageUrl.isNotEmpty) {
          delta.insert({
            'image': imageUrl,
          }, attributes.isNotEmpty ? attributes : null);
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

          // 1. Insert Image
          _quillController.replaceText(
            index,
            length,
            BlockEmbed.image(url),
            null,
          );

          // 2. Apply Center Alignment to the line
          _quillController.formatSelection(Attribute.centerAlignment);

          // 3. Move cursor after (and reset format?)
          _quillController.moveCursorToPosition(index + 1);
          // Optional: reset alignment for new line
          _quillController.formatSelection(Attribute.leftAlignment);
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

        if (op.attributes != null) {
          if (op.attributes!.containsKey('bold')) {
            if (text.trim().isNotEmpty) {
              text = "**${text.trim()}**";
            }
          } else if (op.attributes!.containsKey('italic')) {
            if (text.trim().isNotEmpty) {
              text = "*${text.trim()}*";
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
          var imageUrl = map['image'].toString();

          if (op.attributes != null) {
            final attrs = <String>[];

            // 1. Direct Attributes
            if (op.attributes!.containsKey('width'))
              attrs.add('q_w=${op.attributes!['width']}');
            if (op.attributes!.containsKey('height'))
              attrs.add('q_h=${op.attributes!['height']}');
            if (op.attributes!.containsKey('align'))
              attrs.add('q_a=${op.attributes!['align']}');

            // 2. Style Attribute (CSS String) - Extensions often write here
            if (op.attributes!.containsKey('style')) {
              final style = op.attributes!['style'].toString();
              // Extract width
              final wMatch = RegExp(r'width:\s*([\d\.]+)').firstMatch(style);
              if (wMatch != null && !op.attributes!.containsKey('width')) {
                attrs.add('q_w=${wMatch.group(1)}');
              }
              // Extract height
              final hMatch = RegExp(r'height:\s*([\d\.]+)').firstMatch(style);
              if (hMatch != null && !op.attributes!.containsKey('height')) {
                attrs.add('q_h=${hMatch.group(1)}');
              }
              // Extract alignment (text-align, margin, etc - simplified)
            }

            if (attrs.isNotEmpty) {
              final separator = imageUrl.contains('?') ? '&' : '?';
              imageUrl += '$separator${attrs.join('&')}';
            }
          }

          // Fix: Don't wrap in extra newlines. The loop structure handles block separation.
          // If previous block wasn't newline, we might want one, but let's stick to minimal.
          buffer.write("![image]($imageUrl)");
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

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              if (_selectedImageNode != null)
                _buildImageToolbar(), // Show image toolbar below
            ],
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
                  // Use Custom Builder for full UI control
                  embedBuilders: [
                    StandardImageEmbedBuilder(
                      selectedNode: _selectedImageNode,
                      tempWidth: _tempImageWidth,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Temp state for smooth slider dragging
  double? _tempImageWidth;

  Widget _buildImageToolbar() {
    if (_selectedImageNode == null) return const SizedBox.shrink();

    final style = _selectedImageNode!.style;
    final widthAttr = style.attributes['width'];
    double? currentWidth;
    if (widthAttr != null && widthAttr.value != null) {
      currentWidth = double.tryParse(widthAttr.value.toString());
    }
    // Default to screen width if null (meaning auto/full)
    final maxWidth = MediaQuery.of(context).size.width - 48; // minus padding

    // Use temp width if dragging, otherwise use model width
    double sliderValue = _tempImageWidth ?? currentWidth ?? maxWidth;

    if (sliderValue > maxWidth) sliderValue = maxWidth;
    if (sliderValue < 50.0) sliderValue = 50.0;

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.photo_size_select_large,
            size: 20,
            color: Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                trackHeight: 2,
              ),
              child: Slider(
                value: sliderValue,
                min: 50.0,
                max: maxWidth,
                activeColor: Colors.black87,
                inactiveColor: Colors.grey[300],
                onChangeStart: (val) {
                  setState(() {
                    _tempImageWidth = val;
                  });
                },
                onChanged: (val) {
                  setState(() {
                    _tempImageWidth = val;
                  });
                },
                onChangeEnd: (val) {
                  // Commit changes only on release
                  String? newWidth = val.toString();
                  final maxWidth = MediaQuery.of(context).size.width - 48;
                  if (val >= maxWidth - 10) newWidth = null;

                  // Use AttributeScope.inline to ensure persistence (or try explicit style scope)
                  // Note: 'ignore' scope is often transient.
                  _quillController.formatText(
                    _selectedImageNode!.documentOffset,
                    1,
                    Attribute('width', AttributeScope.inline, newWidth),
                  );

                  // Ensure node is legally updated
                  _refreshSelectedNode();

                  setState(() {
                    _tempImageWidth = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildToolbarBtn(Icons.format_align_left, 'left'),
          _buildToolbarBtn(Icons.format_align_center, 'center'),
          _buildToolbarBtn(Icons.format_align_right, 'right'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () {
              CommonDialog.show(
                title: "确认移除",
                content: "确定要移除这张图片吗？",
                confirmText: "确认",
                cancelText: "取消",
                isDestructive: true,
                onConfirm: () {
                  Get.back(); // Close dialog
                  _quillController.replaceText(
                    _selectedImageNode!.documentOffset,
                    1,
                    '',
                    null,
                  );
                  setState(() => _selectedImageNode = null);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _refreshSelectedNode() {
    if (_selectedImageNode == null) return;

    // We need to re-find the embed node at the exact same location
    // Note: Use document.queryChild(offset)
    final offset = _selectedImageNode!.documentOffset;
    final child = _quillController.document.queryChild(offset);
    Node? newNode = child.node;

    if (newNode is Line) {
      final leaf = newNode.queryChild(child.offset, false);
      newNode = leaf.node;
    }

    if (newNode != null && newNode is Embed) {
      _selectedImageNode = newNode;
    }
  }

  Widget _buildToolbarBtn(IconData icon, String align) {
    final currentAlign = _selectedImageNode!.style.attributes['align']?.value;
    final isSelected =
        currentAlign == align || (currentAlign == null && align == 'center');
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.black : Colors.grey[400],
        size: 20,
      ),
      onPressed: () {
        _quillController.formatText(
          _selectedImageNode!.documentOffset,
          1,
          Attribute('align', AttributeScope.block, align),
        );
        _refreshSelectedNode();
        setState(() {});
      },
    );
  }
}

class StandardImageEmbedBuilder extends EmbedBuilder {
  final Node? selectedNode;
  final double? tempWidth;

  StandardImageEmbedBuilder({this.selectedNode, this.tempWidth});

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

    // Parse current width/height from attributes if available
    double? width;
    double? height;
    final style = embedContext.node.style;

    // Check attributes
    final attrs = style.attributes;
    if (attrs.containsKey('width')) {
      final w = attrs['width']?.value;
      if (w != null) width = double.tryParse(w.toString());
    }

    final isSelected = selectedNode == embedContext.node;

    // Override width if selected and dragging
    if (isSelected && tempWidth != null) {
      width = tempWidth;
    }

    return GestureDetector(
      onTap: () {
        final offset = embedContext.node.documentOffset;
        embedContext.controller.updateSelection(
          TextSelection.collapsed(offset: offset),
          ChangeSource.local,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        alignment: _getAlignment(style),
        child: IntrinsicWidth(
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    ),
                  )
                : null,
            child: Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                width: width ?? 300,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  width: width ?? 300,
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
          ),
        ),
      ),
    );
  }

  AlignmentGeometry _getAlignment(Style style) {
    if (style.attributes.containsKey('align')) {
      final val = style.attributes['align']?.value;
      if (val == 'center') return Alignment.center;
      if (val == 'right') return Alignment.centerRight;
      if (val == 'left') return Alignment.centerLeft;
    }
    return Alignment.center;
  }
}
