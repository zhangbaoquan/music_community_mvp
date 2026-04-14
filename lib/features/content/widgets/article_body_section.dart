/// 文章正文区域 — 渲染标题、作者信息、标签、摘要和富文本内容
///
/// 从 [ArticleDetailView] 拆出的子组件，用于减少主文件行数。
/// 纯展示组件，不包含业务逻辑。
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'article_music_player_card.dart';

/// 文章正文展示组件
///
/// 包含标题、作者头像/昵称、关注按钮、
/// 类型标签、自定义标签、BGM 播放器、摘要引用、富文本内容。
class ArticleBodySection extends StatelessWidget {
  /// 当前文章数据
  final Article article;

  /// Quill 富文本控制器
  final QuillController quillController;

  /// 关注按钮 Widget（由父组件注入，包含交互逻辑）
  final Widget followButton;

  const ArticleBodySection({
    super.key,
    required this.article,
    required this.quillController,
    required this.followButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 文章标题
          Text(
            article.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // 作者信息行
          _buildAuthorRow(),
          const SizedBox(height: 16),

          // 标签行
          _buildTagsRow(),
          const SizedBox(height: 24),

          // BGM 播放器卡片
          const ArticleMusicPlayerCard(),

          // 摘要引用块
          if (article.summary != null && article.summary!.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.blueAccent, width: 4),
                ),
              ),
              child: Text(
                article.summary!,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),

          const Divider(height: 1),

          // Quill 富文本内容
          QuillEditor(
            controller: quillController,
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              autoFocus: false,
              expands: false,
              padding: const EdgeInsets.only(top: 24),
              embedBuilders: FlutterQuillEmbeds.editorBuilders(),
            ),
          ),

          const SizedBox(height: 140),
        ],
      ),
    );
  }

  /// 构建作者信息行（头像 + 昵称 + 关注按钮 + 发布时间）
  Widget _buildAuthorRow() {
    return Row(
      children: [
        // 作者头像
        CircleAvatar(
          radius: 16,
          backgroundImage:
              article.authorAvatar != null && article.authorAvatar!.isNotEmpty
              ? NetworkImage(article.authorAvatar!.toSecureUrl())
              : null,
          child: article.authorAvatar == null || article.authorAvatar!.isEmpty
              ? const Icon(Icons.person, size: 16)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  article.authorName ?? '未知作者',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                followButton,
              ],
            ),
            Text(
              '发布于 ${timeago.format(article.createdAt, locale: 'zh')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建标签行（文章类型 + 自定义标签）
  Widget _buildTagsRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        // 文章类型标签（原创/转载）
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: article.type == 'original'
                ? Colors.blueAccent.withValues(alpha: 0.1)
                : Colors.orangeAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: article.type == 'original'
                  ? Colors.blueAccent
                  : Colors.orangeAccent,
              width: 0.5,
            ),
          ),
          child: Text(
            article.type == 'original' ? '原创' : '转载',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: article.type == 'original'
                  ? Colors.blueAccent
                  : Colors.orangeAccent,
            ),
          ),
        ),
        // 自定义标签
        ...article.tags.map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '# $tag',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
