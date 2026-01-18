import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/notifications/notification_service.dart';
import 'package:music_community_mvp/features/profile/profile_controller.dart';
import 'package:music_community_mvp/features/content/article_detail_view.dart';
import 'package:music_community_mvp/data/models/article.dart'; // Needed for navigation if we fetch article, or we pass ID
import 'package:supabase_flutter/supabase_flutter.dart'; // To fetch article details if needed
import 'package:timeago/timeago.dart' as timeago;

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<NotificationService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('通知中心', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: '全部已读',
            onPressed: () => service.markAllAsRead(),
          ),
        ],
      ),
      body: Obx(() {
        if (service.notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
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

  // We check if we already follow this user when initialized (optional, but good UX)
  // For better performance in a long list, maybe we shouldn't do this for every item.
  // We'll lazy load or just default to "Follow Back".
  // Let's rely on ProfileController cache if possible (not implemented yet).
  // For now: Default false, update on interaction.

  @override
  void initState() {
    super.initState();
    if (widget.notification.type == 'follow') {
      _isFollowLoading = true;
      _checkIfFollowing();
    }
  }

  Future<void> _checkIfFollowing() async {
    // This could spam DB if many notifications.
    // In production we'd batch fetch 'doIFollow(userIds)'.
    // Here we just check this one.
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
    Get.find<NotificationService>().markAsRead(widget.notification.id);

    // Navigation
    if (widget.notification.resourceId != null &&
        (widget.notification.type == 'like_article' ||
            widget.notification.type == 'comment_article')) {
      // Must fetch article details quickly or pass minimal data
      // ArticleDetailView usually expects an Article object.
      // We'll do a quick fetch.

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      try {
        final articleRes = await Supabase.instance.client
            .from('articles')
            .select(
              '*, profiles(username, avatar_url)',
            ) // Minimal needed? Controller will refetch stats
            .eq('id', widget.notification.resourceId!)
            .single();

        Get.back(); // close loading

        if (articleRes != null) {
          final article = Article.fromMap(articleRes);
          Get.to(() => ArticleDetailView(article: article));
        }
      } catch (e) {
        Get.back();
        Get.snackbar('Error', 'Unable to load content');
      }
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
      default:
        typeIcon = Icons.notifications;
        typeColor = Colors.grey;
        actionText = '有新动态';
    }

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
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.notification.actorAvatar.isNotEmpty
                      ? NetworkImage(widget.notification.actorAvatar)
                      : null,
                  child: widget.notification.actorAvatar.isEmpty
                      ? const Icon(Icons.person, size: 24, color: Colors.grey)
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
                          text: widget.notification.actorName,
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
