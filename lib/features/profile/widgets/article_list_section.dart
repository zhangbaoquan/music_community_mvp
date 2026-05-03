/// 文章列表组件 — 展示用户的文章列表
///
/// 从 [ProfileView] 拆出的可复用组件。
/// 支持"我发布的"和"我收藏的"两种列表模式，
/// "我发布的"模式下包含编辑和删除操作。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/features/content/article_controller.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';
import '../../../core/router/app_router.dart';

/// 文章列表
///
/// [articles] 文章列表
/// [isMine] 是否为"我发布的"模式（决定是否显示编辑/删除按钮）
class ArticleListSection extends StatelessWidget {
  final List<Article> articles;
  final bool isMine;

  const ArticleListSection({
    super.key,
    required this.articles,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    final articleController = Get.find<ArticleController>();

    return Obx(() {
      if (articles.isEmpty) {
        return _buildEmptyState(controller);
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: articles.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildArticleCard(article, controller, articleController);
        },
      );
    });
  }

  /// 空状态占位
  Widget _buildEmptyState(ProfileController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMine ? Icons.article_outlined : Icons.bookmark_border,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isMine ? "还没有发布过文章" : "还没有收藏文章",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          if (isMine) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (await controller.checkActionAllowed('发布文章')) {
                  appRouter.push('/editor');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("去写第一篇"),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建单个文章卡片
  Widget _buildArticleCard(
    Article article,
    ProfileController controller,
    ArticleController articleController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              appRouter.push('/article/${article.id}', extra: article),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 封面图
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                    image: article.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(
                              article.coverUrl!.toSecureUrl(),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: article.coverUrl == null
                      ? Icon(Icons.article, color: Colors.grey[300], size: 32)
                      : null,
                ),
                // 内容区
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        article.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      if (article.summary != null &&
                          article.summary!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          article.summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // 底部统计行
                      Row(
                        children: [
                          Icon(Icons.favorite_border,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text("${article.likesCount}",
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(Icons.comment_outlined,
                              size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text("${article.commentsCount}",
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                          const Spacer(),
                          if (isMine) ...[
                            // 编辑按钮
                            _CompactActionButton(
                              icon: Icons.edit,
                              tooltip: "编辑",
                              onTap: () async {
                                if (await controller
                                    .checkActionAllowed('编辑文章')) {
                                  appRouter.push('/editor', extra: article);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            // 删除按钮
                            _CompactActionButton(
                              icon: Icons.delete_outline,
                              tooltip: "删除",
                              color: Colors.red[300],
                              onTap: () async {
                                if (!await controller
                                    .checkActionAllowed('删除文章')) {
                                  return;
                                }
                                Get.dialog(
                                  AlertDialog(
                                    title: const Text("确认删除"),
                                    content: const Text("确定要删除这篇文章吗？操作不可恢复。"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => appRouter.pop(),
                                        child: const Text("取消"),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final success =
                                              await articleController
                                                  .deleteArticle(article.id);
                                          if (success) {
                                            appRouter.pop();
                                            Get.snackbar("删除成功", "文章已删除");
                                          }
                                        },
                                        child: const Text("删除",
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ] else ...[
                            // 收藏文章显示作者名
                            if (article.authorName != null)
                              Text(
                                "@${article.authorName}",
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 12),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 紧凑操作按钮（编辑/删除）
class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _CompactActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, size: 18, color: color ?? Colors.blueGrey[300]),
          ),
        ),
      ),
    );
  }
}
