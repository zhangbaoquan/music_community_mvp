import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import '../../core/widgets/common_dialog.dart';
import '../content/article_controller.dart';
import '../content/article_detail_view.dart';
import '../../data/models/article.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';

class ManageArticlesView extends StatelessWidget {
  const ManageArticlesView({super.key});

  @override
  Widget build(BuildContext context) {
    final articleController = Get.put(ArticleController());

    // We reuse the existing article list for now.
    // In a real app, we might want a paginated table server-side.
    if (articleController.articles.isEmpty) {
      articleController.fetchArticles();
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "文章管理 (最新发布)",
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => articleController.fetchArticles(),
                icon: const Icon(Icons.refresh),
                tooltip: "刷新列表",
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (articleController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final articles = articleController.articles;
              if (articles.isEmpty) {
                return const Center(child: Text("暂无文章"));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 800) {
                    return _buildMobileList(articleController, articles);
                  } else {
                    return _buildDesktopTable(articleController, articles);
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    ArticleController controller,
    List<Article> articles,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          width: MediaQuery.of(Get.context!).size.width > 800
              ? MediaQuery.of(Get.context!).size.width - 250
              : 800,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DataTable(
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text("封面")),
              DataColumn(label: Text("标题")),
              DataColumn(label: Text("作者")),
              DataColumn(label: Text("点赞/评论")),
              DataColumn(label: Text("发布时间")),
              DataColumn(label: Text("操作")),
            ],
            rows: articles
                .map((article) => _buildDataRow(controller, article))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(
    ArticleController controller,
    List<Article> articles,
  ) {
    return ListView.builder(
      itemCount: articles.length,
      itemBuilder: (context, index) {
        final article = articles[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[200],
                image: article.coverUrl != null && article.coverUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(article.coverUrl!.toSecureUrl()),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (article.coverUrl == null || article.coverUrl!.isEmpty)
                  ? const Icon(Icons.article)
                  : null,
            ),
            title: Text(
              article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("作者: ${article.authorName ?? '未知'}"),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.thumb_up, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "${article.likesCount}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.comment, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "${article.commentsCount}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    Text(
                      article.createdAt.toString().split(' ').first,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _confirmDelete(controller, article);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除', style: TextStyle(color: Colors.red)),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
            onTap: () => Get.to(() => ArticleDetailView(article: article)),
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(ArticleController controller, Article article) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
              image: article.coverUrl != null && article.coverUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(article.coverUrl!.toSecureUrl()),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
        ),
        DataCell(
          InkWell(
            onTap: () => Get.to(() => ArticleDetailView(article: article)),
            child: SizedBox(
              width: 200,
              child: Text(article.title, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
        DataCell(Text(article.authorName ?? "Unknown")),
        DataCell(Text("${article.likesCount} / ${article.commentsCount}")),
        DataCell(Text(article.createdAt.toString().split(' ').first)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            tooltip: "删除",
            onPressed: () => _confirmDelete(controller, article),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(ArticleController controller, Article article) {
    CommonDialog.show(
      title: "确认删除",
      content: "确定要删除文章 '${article.title}' 吗？",
      confirmText: "删除",
      cancelText: "取消",
      isDestructive: true,
      onConfirm: () async {
        Get.back(); // close dialog
        await controller.deleteArticle(article.id);
      },
    );
  }
}
