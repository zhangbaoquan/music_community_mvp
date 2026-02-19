import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/notifications/notification_service.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:music_community_mvp/features/profile/user_profile_view.dart';
import 'package:music_community_mvp/data/models/article.dart'; // Needed for navigation if we fetch article, or we pass ID
import 'package:supabase_flutter/supabase_flutter.dart'; // To fetch article details if needed
import 'package:timeago/timeago.dart' as timeago;
import 'package:music_community_mvp/core/utils/string_extensions.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<NotificationService>();

    return Column(
      children: [
        // Custom Header for Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => service.markAllAsRead(),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text("全部已读"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (service.notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('暂无新通知', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: service.notifications.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = service.notifications[index];
                return _NotificationItem(notification: notification);
              },
            );
          }),
        ),
      ],
    );
  }
}

class _NotificationItem extends StatefulWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  // State for Follow Button
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.notification.type == 'follow') {
      _isFollowLoading = true;
      _checkIfFollowing();
    }
  }

  Future<void> _checkIfFollowing() async {
    if (!mounted) return;
    final pc = Get.find<ProfileController>();
    final isFollowing = await pc.checkIsFollowing(widget.notification.actorId);
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _isFollowLoading = false;
      });
    }
  }

  Future<void> _handleFollowAction() async {
    setState(() {
      _isFollowLoading = true;
    });

    final pc = Get.find<ProfileController>();
    bool success;

    if (_isFollowing) {
      success = await pc.unfollowUser(widget.notification.actorId);
      if (success) {
        setState(() {
          _isFollowing = false;
        });
      }
    } else {
      success = await pc.followUser(widget.notification.actorId);
      if (success) {
        setState(() {
          _isFollowing = true;
        });
      }
    }

    setState(() {
      _isFollowLoading = false;
    });
  }

  void _handleTap() async {
    // Mark Read
    try {
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().markAsRead(widget.notification.id);
      }
    } catch (e) {
      print("NotificationService error: $e");
    }

    // Navigation
    if (widget.notification.type == 'follow') {
      Get.toNamed('/profile/${widget.notification.actorId}');
      return;
    }

    if (widget.notification.type == 'feedback_reply' &&
        widget.notification.content != null) {
      Get.dialog(
        AlertDialog(
          title: const Text("管理员回复"),
          content: Text(widget.notification.content!),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("关闭")),
          ],
        ),
      );
      return;
    }

    if (widget.notification.resourceId != null &&
        (widget.notification.type == 'like_article' ||
            widget.notification.type == 'comment_article')) {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      try {
        final articleRes = await Supabase.instance.client
            .from('articles')
            .select('*, profiles(username, avatar_url)')
            .eq('id', widget.notification.resourceId!)
            .maybeSingle(); // Use maybeSingle to avoid exception on deleted items

        // Close loading dialog if open
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }

        if (articleRes != null) {
          final article = Article.fromMap(articleRes);
          // Auto-open comments if it's a comment or like_comment notification
          // Assuming 'comment_article' or 'like_comment'
          final isCommentAction =
              widget.notification.type == 'comment_article' ||
              widget.notification.type == 'like_comment';

          Get.toNamed(
            '/article/${article.id}?autoOpen=$isCommentAction',
            arguments: article,
          );
        } else {
          Get.snackbar('提示', '该内容可能已被删除');
        }
      } catch (e) {
        print("Error fetching article: $e");
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        Get.snackbar('错误', '无法加载内容');
      }
    }

    if (widget.notification.type == 'system_warning' &&
        widget.notification.content != null) {
      Get.dialog(
        AlertDialog(
          title: const Text("系统通知", style: TextStyle(color: Colors.red)),
          content: Text(widget.notification.content!),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("了解")),
          ],
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    IconData typeIcon;
    Color typeColor;
    String actionText;

    switch (widget.notification.type) {
      case 'follow':
        typeIcon = Icons.person_add;
        typeColor = Colors.blue;
        actionText = '关注了你';
        break;
      case 'like_article':
        typeIcon = Icons.favorite;
        typeColor = Colors.red;
        actionText = '赞了你的文章';
        break;
      case 'comment_article':
        typeIcon = Icons.comment;
        typeColor = Colors.green;
        actionText = '评论了你的文章';
        break;
      case 'like_comment':
        typeIcon = Icons.favorite_border;
        typeColor = Colors.pink;
        actionText = '赞了你的评论';
        break;
      case 'feedback_reply':
        typeIcon = Icons.support_agent;
        typeColor = Colors.orange;
        actionText = '回复了你的反馈';
        break;
      case 'system_warning':
        typeIcon = Icons.warning_amber_rounded;
        typeColor = Colors.redAccent;
        actionText = '系统警告';
        break;
      default:
        typeIcon = Icons.notifications;
        typeColor = Colors.grey;
        actionText = '有新动态';
    }

    // Override for Feedback Reply (System Message)
    final isSystemReply =
        widget.notification.type == 'feedback_reply' ||
        widget.notification.type == 'system_warning';
    final displayName = isSystemReply ? "系统管理员" : widget.notification.actorName;
    final displayAvatar = isSystemReply ? "" : widget.notification.actorAvatar;

    return InkWell(
      onTap: _handleTap,
      child: Container(
        color: widget.notification.isRead
            ? Colors.white
            : Colors.blue.withValues(alpha: 0.05),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with Type Badge
            GestureDetector(
              onTap: () {
                if (!isSystemReply) {
                  Get.to(
                    () => UserProfileView(userId: widget.notification.actorId),
                  );
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: displayAvatar.isNotEmpty
                        ? NetworkImage(displayAvatar.toSecureUrl())
                        : null,
                    backgroundColor: isSystemReply ? Colors.orange[100] : null,
                    child: displayAvatar.isEmpty
                        ? Icon(
                            isSystemReply ? Icons.support_agent : Icons.person,
                            size: 24,
                            color: isSystemReply ? Colors.orange : Colors.grey,
                          )
                        : null,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(typeIcon, size: 14, color: typeColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: actionText,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (widget.notification.content != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.notification.content!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(widget.notification.createdAt, locale: 'zh'),
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Follow Button (Only for 'follow' type)
            if (widget.notification.type == 'follow') ...[
              const SizedBox(width: 16),
              SizedBox(
                height: 32,
                child: _isFollowLoading
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _isFollowing
                    ? OutlinedButton(
                        onPressed: _handleFollowAction,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '已关注',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _handleFollowAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('回关', style: TextStyle(fontSize: 12)),
                      ),
              ),
            ],

            // Chevron for others (optional)
            if (widget.notification.type != 'follow' &&
                widget.notification.resourceId != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}
