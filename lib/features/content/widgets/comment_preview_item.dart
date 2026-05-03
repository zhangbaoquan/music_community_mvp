/// 评论预览卡片 — 在文章详情页底部展示单条评论的摘要信息
///
/// 用于评论区列表中，点击可展开评论楼中楼。
/// 长按可举报评论。
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:music_community_mvp/data/models/article_comment.dart';
import 'package:music_community_mvp/core/utils/string_extensions.dart';
import 'package:music_community_mvp/features/content/article_controller.dart';
import 'package:music_community_mvp/features/safety/report_dialog.dart';
import '../../../core/router/app_router.dart';

/// 评论预览组件
///
/// 展示评论摘要（头像、昵称、时间、内容、点赞、回复数），
/// 点击 [onTap] 打开楼中楼详情。
class CommentPreviewItem extends StatelessWidget {
  /// 评论数据
  final ArticleComment comment;

  /// 点击回调（通常打开评论楼中楼抽屉）
  final VoidCallback onTap;

  const CommentPreviewItem({
    super.key,
    required this.comment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      // 长按弹出举报菜单
      onLongPress: () {
        Get.bottomSheet(
          Container(
            color: Colors.white,
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.report_problem, color: Colors.red),
                  title: const Text(
                    '举报评论',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    appRouter.pop();
                    Get.dialog(
                      ReportDialog(
                        targetType: 'comment',
                        targetId: comment.id,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF8F8F8))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户头像
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  comment.userAvatar != null && comment.userAvatar!.isNotEmpty
                  ? NetworkImage(comment.userAvatar!.toSecureUrl())
                  : null,
              child: comment.userAvatar == null || comment.userAvatar!.isEmpty
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名 + 时间 + 点赞按钮
                  Row(
                    children: [
                      Text(
                        comment.userName ?? '未知用户',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(comment.createdAt, locale: 'zh'),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 评论点赞按钮
                      GestureDetector(
                        onTap: () =>
                            Get.find<ArticleController>().toggleCommentLike(
                              comment,
                            ),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 14,
                              color: comment.isLiked
                                  ? Colors.red
                                  : Colors.grey[400],
                            ),
                            if (comment.likesCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '${comment.likesCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: comment.isLiked
                                      ? Colors.red
                                      : Colors.grey[400],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 评论内容（最多显示 3 行）
                  Text(
                    comment.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  // 回复数量标签
                  if (comment.totalRepliesCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${comment.totalRepliesCount} 条回复 >',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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
