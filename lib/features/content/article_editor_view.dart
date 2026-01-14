import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'article_controller.dart';
import 'dart:convert';

class ArticleEditorView extends StatefulWidget {
  const ArticleEditorView({super.key});

  @override
  State<ArticleEditorView> createState() => _ArticleEditorViewState();
}

class _ArticleEditorViewState extends State<ArticleEditorView> {
  final _controller = Get.find<ArticleController>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _quillController = QuillController.basic();

  // PlatformFile?
  // _coverFile; // For Web/Desktop compatibility using FilePicker if needed, or stick to ImagePicker
  // Actually, ArticleController expects PlatformFile for web compat in the plan?
  // Let's check ArticleController. It expects PlatformFile?
  // Yes: publishArticle({..., PlatformFile? coverFile})

  // We'll use FilePicker for consistency with Music Upload, or ImagePicker and convert.
  // Let's use FilePicker for cover to be safe on web? Or ImagePicker.
  // Music Upload used FilePicker for audio and ImagePicker for cover.
  // Let's use ImagePicker XFile and convert to PlatformFile bytes.

  XFile? _pickedCover;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedCover = image;
      });
    }
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('Tip', 'Please enter a title');
      return;
    }

    // Convert XFile to PlatformFile for Controller
    PlatformFile? coverPlatformFile;
    if (_pickedCover != null) {
      final bytes = await _pickedCover!.readAsBytes();
      coverPlatformFile = PlatformFile(
        name: _pickedCover!.name,
        size: await _pickedCover!.length(),
        bytes: bytes,
      );
    }

    final contentJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );

    final success = await _controller.publishArticle(
      title: _titleController.text,
      summary: _summaryController.text,
      contentJson: jsonDecode(
        contentJson,
      ), // Controller expects List/Map, typically List<dynamic> from Delta
      coverFile: coverPlatformFile,
    );

    if (success) {
      Get.snackbar(
        '发布成功',
        '您的文章已发布！',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
      // Wait for snackbar to be visible briefly before closing
      await Future.delayed(const Duration(milliseconds: 500));
      // Close the snackbar AND the page
      Get.back(closeOverlays: true);
    } else {
      Get.snackbar(
        '发布失败',
        '请稍后重试或检查网络',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写文章'),
        actions: [
          Obx(() {
            return TextButton(
              onPressed: _controller.isUploading.value ? null : _submit,
              child: _controller.isUploading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('发布', style: TextStyle(fontSize: 16)),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Cover Image Header
                  GestureDetector(
                    onTap: _pickCover,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        image: _pickedCover != null
                            ? DecorationImage(
                                image: NetworkImage(_pickedCover!.path),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _pickedCover == null
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '添加封面图',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Title
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: '输入标题...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 12),

                  // 3. Summary
                  TextField(
                    controller: _summaryController,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    decoration: const InputDecoration(
                      hintText: '简短摘要或副标题 (可选)...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                  const Divider(height: 40),

                  // 4. Rich Text Editor
                  QuillEditor(
                    controller: _quillController,
                    focusNode: FocusNode(),
                    scrollController: ScrollController(),
                    config: const QuillEditorConfig(
                      placeholder: '开始撰写你的故事...',
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Toolbar at bottom
          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(
              showSearchButton: false,
              showInlineCode: false,
              showSubscript: false,
              showSuperscript: false,
            ),
          ),
        ],
      ),
    );
  }
}
