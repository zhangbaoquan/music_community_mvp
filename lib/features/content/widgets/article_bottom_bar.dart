/// 文章详情页底部操作栏 — 包含评论输入框和操作按钮
///
/// 操作按钮包括：点赞、收藏、分享、举报。
/// 评论输入框点击后打开评论抽屉。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_community_mvp/data/models/article.dart';
import 'package:music_community_mvp/features/content/article_controller.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:music_community_mvp/features/safety/report_dialog.dart';
import 'bottom_action_btn.dart';

/// 文章详情页底部操作栏
///
/// [article] 当前文章数据
/// [scaffoldKey] 用于打开评论抽屉
/// [onStateChanged] 互动操作后的回调（用于刷新 UI）
class ArticleBottomBar extends StatelessWidget {
  final Article article;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onStateChanged;

  const ArticleBottomBar({
    super.key,
    required this.article,
    required this.scaffoldKey,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 评论输入框（点击打开评论抽屉）
            Expanded(child: _buildCommentInput()),
            const SizedBox(width: 24),
            // 操作按钮组
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建评论输入框占位区域
  Widget _buildCommentInput() {
    return GestureDetector(
      onTap: () async {
        if (!await Get.find<ProfileController>()
            .checkActionAllowed('发布评论')) {
          return;
        }
        // 清空选中的评论线程，以「发表新评论」模式打开
        Get.find<ArticleController>().selectedThread.value = null;
        scaffoldKey.currentState?.openEndDrawer();
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.edit, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Text(
              '写下你的想法...',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮组（点赞、收藏、分享、举报）
  Widget _buildActionButtons() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 点赞
        BottomActionBtn(
          icon: article.isLiked ? Icons.favorite : Icons.favorite_border,
          label: article.likesCount.toString(),
          isActive: article.isLiked,
          activeColor: Colors.red,
          onTap: () async {
            await Get.find<ArticleController>().toggleLike(article);
            onStateChanged();
          },
        ),
        const SizedBox(width: 16),
        // 收藏
        BottomActionBtn(
          icon: article.isCollected ? Icons.bookmark : Icons.bookmark_border,
          label: article.collectionsCount.toString(),
          isActive: article.isCollected,
          activeColor: Colors.orange,
          onTap: () async {
            await Get.find<ArticleController>().toggleCollection(article);
            onStateChanged();
          },
        ),
        const SizedBox(width: 16),
        // 分享
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black54),
          onPressed: () => Get.snackbar("提示", "分享功能开发中"),
        ),
        const SizedBox(width: 8),
        // 举报（仅对他人文章显示）
        if (article.userId != currentUserId)
          IconButton(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.black54,
            ),
            onPressed: () async {
              if (!await Get.find<ProfileController>()
                  .checkActionAllowed('举报内容')) {
                return;
              }
              Get.dialog(
                ReportDialog(
                  targetType: 'article',
                  targetId: article.id,
                ),
              );
            },
          ),
      ],
    );
  }
}
