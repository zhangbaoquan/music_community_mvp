import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_community_mvp/features/notifications/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure service is found (it should be put in MainLayout or bindings)
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

        return ListView.builder(
          itemCount: service.notifications.length,
          itemBuilder: (context, index) {
            final notification = service.notifications[index];
            return _NotificationItem(notification: notification);
          },
        );
      }),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    String text;

    switch (notification.type) {
      case 'follow':
        icon = Icons.person_add;
        iconColor = Colors.blue;
        text = '关注了你';
        break;
      case 'like_article':
        icon = Icons.favorite;
        iconColor = Colors.red;
        text = '赞了你的文章';
        break;
      case 'comment_article':
        icon = Icons.comment;
        iconColor = Colors.green;
        text = '评论了你的文章';
        break;
      case 'like_comment':
        icon = Icons.favorite_border;
        iconColor = Colors.pink;
        text = '赞了你的评论';
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
        text = '有新动态';
    }

    return InkWell(
      onTap: () {
        Get.find<NotificationService>().markAsRead(notification.id);
        // TODO: Navigate to specific resource based on type and resourceId
      },
      child: Container(
        color: notification.isRead
            ? Colors.transparent
            : Colors.blue.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Actor Avatar
            CircleAvatar(
              radius: 20,
              backgroundImage: notification.actorAvatar.isNotEmpty
                  ? NetworkImage(notification.actorAvatar)
                  : null,
              child: notification.actorAvatar.isEmpty
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        notification.actorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(text),
                    ],
                  ),
                  if (notification.content != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.content!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt, locale: 'zh'),
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
            ),

            // Icon Badge
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}
