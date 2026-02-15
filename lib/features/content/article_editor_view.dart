import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/features/content/music_picker_sheet.dart';
import 'package:music_community_mvp/features/content/article_image_embed_builder.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'article_controller.dart';
import 'dart:convert';

class ArticleEditorView extends StatefulWidget {
  final Article? article;
  const ArticleEditorView({super.key, this.article});

  @override
  State<ArticleEditorView> createState() => _ArticleEditorViewState();
}

class _ArticleEditorViewState extends State<ArticleEditorView> {
  final _controller = Get.find<ArticleController>();
  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late QuillController _quillController;

  XFile? _pickedCover;
  String? _selectedBgmId;
  String? _selectedBgmTitle;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _summaryController = TextEditingController(
      text: widget.article?.summary ?? '',
    );

    // Initialize BGM
    _selectedBgmId = widget.article?.bgmSongId;
    _selectedBgmTitle = widget.article?.bgmTitle;

    // Initialize Quill Controller
    if (widget.article != null && widget.article!.content != null) {
      try {
        final doc = Document.fromJson(widget.article!.content!);
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        print("Error parsing article content: $e");
        _quillController = QuillController.basic();
      }
    } else {
      _quillController = QuillController.basic();
    }
  }

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

  void _pickBgm() {
    Get.bottomSheet(
      MusicPickerSheet(
        onSelected: (id, title) {
          setState(() {
            _selectedBgmId = id;
            _selectedBgmTitle = title;
          });
        },
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _handleImageButton() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        // Upload to Supabase
        final bytes = await image.readAsBytes();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        final path = 'article_images/$fileName';

        await Supabase.instance.client.storage
            .from('articles')
            .uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(upsert: false),
            );

        final imageUrl = Supabase.instance.client.storage
            .from('articles')
            .getPublicUrl(path);

        // Insert into editor
        final index = _quillController.selection.baseOffset;
        final length = _quillController.selection.extentOffset - index;
        _quillController.replaceText(
          index,
          length,
          BlockEmbed.image(imageUrl),
          null,
        );

        // Move cursor to next line
        _quillController.moveCursorToPosition(index + 1);
      } catch (e) {
        print('Image upload failed: $e');
        Get.snackbar('上传失败', '图片上传失败，请重试');
      }
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
    final contentList = jsonDecode(contentJson);

    bool success;
    if (widget.article != null) {
      // Update
      success = await _controller.updateArticle(
        articleId: widget.article!.id,
        title: _titleController.text,
        summary: _summaryController.text,
        contentJson: contentList,
        coverFile: coverPlatformFile,
        bgmSongId: _selectedBgmId,
      );
    } else {
      // Create
      success = await _controller.publishArticle(
        title: _titleController.text,
        summary: _summaryController.text,
        contentJson: contentList,
        coverFile: coverPlatformFile,
        bgmSongId: _selectedBgmId,
      );
    }

    if (success) {
      Get.snackbar(
        '发布成功',
        widget.article != null ? '您的文章已更新！' : '您的文章已发布！',
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
        title: Text(widget.article != null ? '编辑文章' : '写文章'),
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
                  : Text(
                      widget.article != null ? '更新' : '发布',
                      style: const TextStyle(fontSize: 16),
                    ),
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
                            : (widget.article?.coverUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        widget.article!.coverUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                      ),
                      child:
                          (_pickedCover == null &&
                              widget.article?.coverUrl == null)
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

                  // BGM Selector
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickBgm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedBgmId == null
                                ? Icons.music_note_outlined
                                : Icons.music_note,
                            size: 16,
                            color: _selectedBgmId == null
                                ? Colors.grey
                                : Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedBgmTitle ?? '添加背景音乐',
                            style: TextStyle(
                              color: _selectedBgmId == null
                                  ? Colors.grey
                                  : Colors.blue,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_selectedBgmId != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBgmId = null;
                                  _selectedBgmTitle = null;
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 40),

                  // 4. Rich Text Editor
                  QuillEditor(
                    controller: _quillController,
                    focusNode: FocusNode(),
                    scrollController: ScrollController(),
                    config: QuillEditorConfig(
                      placeholder: '开始撰写你的故事...',
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                      embedBuilders: [
                        ArticleImageEmbedBuilder(),
                        ...FlutterQuillEmbeds.editorBuilders(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Toolbar at bottom
          // Toolbar at bottom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Custom Image Button
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  tooltip: '插入图片',
                  onPressed: _handleImageButton,
                  color: Colors.black54,
                ),
                // Divider
                Container(
                  width: 1,
                  height: 24,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Standard Toolbar
                Expanded(
                  child: QuillSimpleToolbar(
                    controller: _quillController,
                    config: const QuillSimpleToolbarConfig(
                      showSearchButton: false,
                      showInlineCode: false,
                      showSubscript: false,
                      showSuperscript: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
