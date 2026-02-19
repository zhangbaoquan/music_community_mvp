import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'article_controller.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';
import '../profile/profile_controller.dart';

import 'package:timeago/timeago.dart' as timeago;

class ArticleListView extends StatelessWidget {
  const ArticleListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure Controller is initialized
    final controller = Get.put(ArticleController());

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await Get.find<ProfileController>().checkActionAllowed('发布文章')) {
            Get.toNamed('/editor');
          }
        },
        child: const Icon(Icons.edit_note),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.articles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('暂无文章', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchArticles,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.articles.length,
            itemBuilder: (context, index) {
              final article = controller.articles[index];
              return _ArticleCard(article: article);
            },
          ),
        );
      }),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/article/${article.id}', arguments: article);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            if (article.coverUrl != null)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(article.coverUrl!.toSecureUrl()),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: article.authorAvatar != null
                            ? NetworkImage(article.authorAvatar!.toSecureUrl())
                            : null,
                        child: article.authorAvatar == null
                            ? const Icon(Icons.person, size: 12)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        article.authorName ?? '未知作者',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        // timeago.setLocaleMessages('zh', ...) is done in main.dart
                        timeago.format(article.createdAt, locale: 'zh'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),

                  if (article.summary != null &&
                      article.summary!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      article.summary!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Social Interactions
                  Row(
                    children: [
                      _SocialIcon(
                        icon: article.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: article.isLiked ? Colors.red : Colors.grey[400],
                        count: article.likesCount,
                        onTap: () {
                          Get.find<ArticleController>().toggleLike(article);
                        },
                      ),
                      const SizedBox(width: 20),
                      _SocialIcon(
                        icon: Icons.chat_bubble_outline,
                        color: Colors.grey[400],
                        count: article.commentsCount,
                        onTap: () {
                          Get.toNamed(
                            '/article/${article.id}',
                            arguments: article,
                          );
                        },
                      ),
                      const SizedBox(width: 20),
                      _SocialIcon(
                        icon: article.isCollected
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: article.isCollected
                            ? Colors.orange
                            : Colors.grey[400],
                        count: article.collectionsCount,
                        onTap: () {
                          Get.find<ArticleController>().toggleCollection(
                            article,
                          );
                        },
                      ),
                      const Spacer(),
                      // Move time to here? No, keep author at top is fine.
                      // Or maybe optional: Share icon
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final int count;
  final VoidCallback onTap;

  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(
            count > 0 ? '$count' : ' ', // Hide 0 or show? ' ' keeps layout
            style: TextStyle(
              fontSize: 13,
              color: color ?? Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
