import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/core/shim_google_fonts.dart';
import 'package:music_community_mvp/features/content/article_controller.dart';
import 'package:music_community_mvp/features/content/article_detail_view.dart';
import 'package:music_community_mvp/data/models/article.dart';

class UserArticlesView extends GetView<ArticleController> {
  const UserArticlesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Obx(() {
          final count = controller.userArticles.length;
          return Text(
            '我的文章 ($count)',
            style: GoogleFonts.outfit(
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.bold,
            ),
          );
        }),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final articles = controller.userArticles;

        if (articles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  "这里还空空如也",
                  style: GoogleFonts.outfit(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // Responsive logic similar to BadgeDetailView
            int crossAxisCount = 1;
            if (width > 600) crossAxisCount = 2;
            if (width > 900) crossAxisCount = 3;
            if (width > 1200) crossAxisCount = 4;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 140, // Compact height
                  ),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return _buildArticleCard(article);
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildArticleCard(Article article) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              Get.toNamed('/article/${article.id}', arguments: article),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Cover
                Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    image: article.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(article.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: article.coverUrl == null
                      ? Icon(Icons.article, color: Colors.grey[300], size: 32)
                      : null,
                ),
                // Content
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
                      if (article.summary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          article.summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${article.likesCount}",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.comment_outlined,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${article.commentsCount}",
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            article.createdAt.toString().split(' ').first,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
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
