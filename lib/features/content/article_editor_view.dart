/// 文章编辑器 — 创建/编辑文章的表单页面
///
/// 功能包括：封面图选择、标题/摘要输入、BGM 选择、
/// 文章类型选择、标签管理、Quill 富文本编辑。
///
/// 所有 Supabase 操作（图片上传、文章发布）通过 [ArticleService] 完成。
/// 子组件拆分到 widgets/ 目录：
/// - [EditorTagSelector]：标签选择区域
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/data/services/article_service.dart';
import 'package:music_community_mvp/features/content/music_picker_sheet.dart';
import 'package:music_community_mvp/features/content/article_image_embed_builder.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'article_controller.dart';
import 'dart:convert';
import 'widgets/editor_tag_selector.dart';

class ArticleEditorView extends StatefulWidget {
  final Article? article;
  const ArticleEditorView({super.key, this.article});

  @override
  State<ArticleEditorView> createState() => _ArticleEditorViewState();
}

class _ArticleEditorViewState extends State<ArticleEditorView> {
  final _controller = Get.find<ArticleController>();

  /// 数据服务层 — 用于图片上传
  final _articleService = ArticleService();

  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  TextEditingController? _tagController;
  late QuillController _quillController;

  XFile? _pickedCover;
  String? _selectedBgmId;
  String? _selectedBgmTitle;
  String _selectedType = 'original';
  List<String> _selectedTags = [];

  /// 主题色（橙色）
  final Color _primaryColor = const Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _summaryController = TextEditingController(
      text: widget.article?.summary ?? '',
    );
    _tagController = TextEditingController();

    // 初始化文章类型和标签
    if (widget.article != null) {
      _selectedType = widget.article!.type;
      _selectedTags = List.from(widget.article!.tags);
    }

    // 初始化 BGM
    _selectedBgmId = widget.article?.bgmSongId;
    _selectedBgmTitle = widget.article?.bgmTitle;

    // 初始化 Quill 编辑器
    _initQuillController();
  }

  /// 初始化富文本编辑器（加载已有内容或创建空白编辑器）
  void _initQuillController() {
    if (widget.article != null && widget.article!.content != null) {
      try {
        final doc = Document.fromJson(widget.article!.content!);
        _quillController = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
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
    _tagController?.dispose();
    _quillController.dispose();
    super.dispose();
  }

  /// 选择封面图
  Future<void> _pickCover() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _pickedCover = image);
    }
  }

  /// 选择背景音乐
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

  /// 插入图片到编辑器（通过 ArticleService 上传）
  Future<void> _handleImageButton() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final bytes = await image.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      // 通过 Service 上传（不直接调 Supabase）
      final imageUrl = await _articleService.uploadArticleImage(
        fileName: fileName,
        fileBytes: bytes,
      );

      // 插入图片到编辑器当前光标位置
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(
        index,
        length,
        BlockEmbed.image(imageUrl),
        null,
      );
      _quillController.moveCursorToPosition(index + 1);
    } catch (e) {
      Get.snackbar('上传失败', '图片上传失败，请重试');
    }
  }

  /// 提交文章（创建或更新）
  void _submit() async {
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar('提示', '请输入文章标题');
      return;
    }

    // 将 XFile 转为 PlatformFile
    PlatformFile? coverPlatformFile;
    if (_pickedCover != null) {
      final bytes = await _pickedCover!.readAsBytes();
      coverPlatformFile = PlatformFile(
        name: _pickedCover!.name,
        size: await _pickedCover!.length(),
        bytes: bytes,
      );
    }

    // 序列化富文本内容
    final contentJson = jsonEncode(
      _quillController.document.toDelta().toJson(),
    );
    final contentList = jsonDecode(contentJson);

    bool success;
    if (widget.article != null) {
      success = await _controller.updateArticle(
        articleId: widget.article!.id,
        title: _titleController.text,
        summary: _summaryController.text,
        contentJson: contentList,
        coverFile: coverPlatformFile,
        bgmSongId: _selectedBgmId,
        type: _selectedType,
        tags: _selectedTags,
      );
    } else {
      success = await _controller.publishArticle(
        title: _titleController.text,
        summary: _summaryController.text,
        contentJson: contentList,
        coverFile: coverPlatformFile,
        bgmSongId: _selectedBgmId,
        type: _selectedType,
        tags: _selectedTags,
      );
    }

    if (success) {
      Get.snackbar(
        '发布成功',
        widget.article != null ? '您的文章已更新！' : '您的文章已发布！',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      Get.back(closeOverlays: true);
    } else {
      Get.snackbar(
        '发布失败',
        '请稍后重试或检查网络',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
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
                      width: 20, height: 20,
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
                  // 封面图
                  _buildCoverPicker(),
                  const SizedBox(height: 24),
                  // 标题
                  _buildTitleField(),
                  const SizedBox(height: 12),
                  // 摘要
                  _buildSummaryField(),
                  const SizedBox(height: 12),
                  // BGM 选择器
                  _buildBgmSelector(),
                  const SizedBox(height: 24),
                  // 文章类型选择
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  // 标签选择器（独立组件）
                  EditorTagSelector(
                    primaryColor: _primaryColor,
                    selectedTags: _selectedTags,
                    tagController: _tagController ??= TextEditingController(),
                    onTagsChanged: () => setState(() {}),
                  ),
                  const Divider(height: 40),
                  // 富文本编辑器
                  _buildQuillEditor(),
                ],
              ),
            ),
          ),
          // 底部工具栏
          _buildToolbar(context),
        ],
      ),
    );
  }

  /// 封面图选择区域
  Widget _buildCoverPicker() {
    return GestureDetector(
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
                      image: NetworkImage(widget.article!.coverUrl!),
                      fit: BoxFit.cover,
                    )
                  : null),
        ),
        child: (_pickedCover == null && widget.article?.coverUrl == null)
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('添加封面图', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  /// 标题输入框
  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        hintText: '输入标题...',
        border: InputBorder.none,
      ),
      maxLines: null,
    );
  }

  /// 摘要输入框
  Widget _buildSummaryField() {
    return TextField(
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
    );
  }

  /// BGM 选择器
  Widget _buildBgmSelector() {
    return GestureDetector(
      onTap: _pickBgm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              color: _selectedBgmId == null ? Colors.grey : Colors.blue,
            ),
            const SizedBox(width: 6),
            Text(
              _selectedBgmTitle ?? '添加背景音乐',
              style: TextStyle(
                color: _selectedBgmId == null ? Colors.grey : Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_selectedBgmId != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedBgmId = null;
                  _selectedBgmTitle = null;
                }),
                child: const Icon(Icons.close, size: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 文章类型选择
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("文章类型"),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildTypeChip('原创', 'original'),
            const SizedBox(width: 12),
            _buildTypeChip('转载', 'repost'),
          ],
        ),
      ],
    );
  }

  /// 段落标题（带竖线装饰）
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 16,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  /// 类型选择 Chip
  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Quill 富文本编辑器
  Widget _buildQuillEditor() {
    return QuillEditor(
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
    );
  }

  /// 底部工具栏
  Widget _buildToolbar(BuildContext context) {
    return Container(
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
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: '插入图片',
            onPressed: _handleImageButton,
            color: Colors.black54,
          ),
          Container(
            width: 1, height: 24,
            color: Colors.grey[300],
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
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
    );
  }
}
