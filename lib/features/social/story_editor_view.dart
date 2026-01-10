import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  final TextEditingController textController = TextEditingController();

  // FocusNode to handle keyboard immediately
  final FocusNode _focusNode = FocusNode();

  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill content if editing
    if (widget.initialContent != null) {
      textController.text = widget.initialContent!;
    }

    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() => isUploading = true);

        final bytes = await image.readAsBytes();
        // Simple extension extraction
        final name = image.name;
        final ext = name.contains('.') ? name.split('.').last : 'jpg';

        final url = await controller.uploadImage(bytes, ext);

        setState(() => isUploading = false);

        if (url != null) {
          _insertTextAtCursor("\n![图片]($url)\n");
        }
      }
    } catch (e) {
      setState(() => isUploading = false);
      Get.snackbar("Error", "Could not pick image");
    }
  }

  void _insertTextAtCursor(String text) {
    if (textController.selection.baseOffset < 0) {
      // No selection, append to end
      textController.text += text;
      return;
    }

    final textSelection = textController.selection;
    final newText = textController.text.replaceRange(
      textSelection.start,
      textSelection.end,
      text,
    );
    final myTextLength = text.length;
    textController.text = newText;
    textController.selection = textSelection.copyWith(
      baseOffset: textSelection.start + myTextLength,
      extentOffset: textSelection.start + myTextLength,
    );
  }

  void _handlePost() {
    if (textController.text.trim().isNotEmpty) {
      if (widget.editingCommentId != null) {
        controller.updateComment(widget.editingCommentId!, textController.text);
      } else {
        controller.postComment(textController.text);
      }
      Get.back(); // Close editor
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Paper-like white
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
          // Insert Image Button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: isUploading ? null : _pickImage,
              icon: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black54,
                      ),
                    )
                  : const Icon(Icons.image_outlined, color: Colors.black87),
              tooltip: "插入图片",
            ),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Divider(),
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: _focusNode,
                maxLines: null, // Unlimited lines
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  height: 1.8, // Comfortable line height for reading/writing
                  color: const Color(0xFF2A2A2A),
                ),
                decoration: InputDecoration(
                  hintText:
                      "这里不仅是评论区，更是你的精神角落...\n\n支持 Markdown 排版，点击上方图片按钮插入图片。",
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.grey[300],
                    fontSize: 18,
                    height: 1.8,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
