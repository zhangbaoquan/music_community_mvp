import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/shim_google_fonts.dart';
import '../../core/widgets/common_dialog.dart';
import '../content/article_controller.dart';
import '../content/article_detail_view.dart';

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

              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
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
                    rows: articles.map((article) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.grey[200],
                                image:
                                    article.coverUrl != null &&
                                        article.coverUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(article.coverUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          DataCell(
                            InkWell(
                              onTap: () => Get.to(
                                () => ArticleDetailView(article: article),
                              ),
                              child: SizedBox(
                                width: 200,
                                child: Text(
                                  article.title,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(article.authorName ?? "Unknown")),
                          DataCell(
                            Text(
                              "${article.likesCount} / ${article.commentsCount}",
                            ),
                          ),
                          DataCell(
                            Text(article.createdAt.toString().split(' ').first),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: "删除",
                              onPressed: () {
                                CommonDialog.show(
                                  title: "确认删除",
                                  content: "确定要删除文章 '${article.title}' 吗？",
                                  confirmText: "删除",
                                  cancelText: "取消",
                                  isDestructive: true,
                                  onConfirm: () async {
                                    Get.back(); // close dialog
                                    await articleController.deleteArticle(
                                      article.id,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
