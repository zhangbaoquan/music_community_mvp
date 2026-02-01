import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationModel {
  final String id;
  final String actorId;
  final String actorName;
  final String actorAvatar;
  final String
  type; // 'follow', 'like_article', 'comment_article', 'like_comment'
  final String? resourceId;
  final String? content;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorAvatar,
    required this.type,
    this.resourceId,
    this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    // Handle joined author data if available, or fallback
    // Note: In a real Supabase join, it might look like 'actor:profiles(...)'
    final actorData = map['actor'] as Map<String, dynamic>? ?? {};

    return NotificationModel(
      id: map['id'],
      actorId: map['actor_id'],
      actorName: actorData['username'] ?? '未知用户',
      actorAvatar: actorData['avatar_url'] ?? '',
      type: map['type'],
      resourceId: map['resource_id'],
      content: map['content'],
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']).toLocal(),
    );
  }
}

class NotificationService extends GetxService {
  final _supabase = Supabase.instance.client;
  final notifications = <NotificationModel>[].obs;
  final unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // In a real app, we might want to listen to realtime changes here
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('notifications')
          .select('*, actor:actor_id(username, avatar_url)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);

      final List<dynamic> data = response;
      final rawNotifications = data
          .map((e) => NotificationModel.fromMap(e))
          .toList();

      // Client-side De-duplication Logic
      final uniqueNotifications = <NotificationModel>[];
      final seenKeys = <String>{};

      for (var n in rawNotifications) {
        String key;
        if (n.type == 'follow') {
          // For 'follow', only keep the latest one per user
          key = 'follow_${n.actorId}';
        } else {
          // For others, duplicate if same actor, type, resource, and content
          key = '${n.type}_${n.actorId}_${n.resourceId}_${n.content}';
        }

        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          uniqueNotifications.add(n);
        }
      }

      notifications.value = uniqueNotifications;

      // Update unread count
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      // Update local state
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final old = notifications[index];
        notifications[index] = NotificationModel(
          id: old.id,
          actorId: old.actorId,
          actorName: old.actorName,
          actorAvatar: old.actorAvatar,
          type: old.type,
          resourceId: old.resourceId,
          content: old.content,
          isRead: true, // Mark as read
          createdAt: old.createdAt,
        );
        unreadCount.value = notifications.where((n) => !n.isRead).length;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);

      fetchNotifications(); // Refresh
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Static helper to send a notification
  /// [recipientId]: Who gets the notification
  /// [type]: 'follow', 'like_article', 'comment_article'
  static Future<void> sendNotification({
    required String recipientId,
    required String type,
    String? resourceId,
    String? content,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    if (currentUser.id == recipientId) return; // Don't notify self

    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': recipientId,
        'actor_id': currentUser.id,
        'type': type,
        'resource_id': resourceId,
        'content': content,
      });
    } catch (e) {
      print('Error sending notification: $e');
      // Fail silently to not disrupt the main action
    }
  }
}
