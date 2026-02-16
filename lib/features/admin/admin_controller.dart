import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_community_mvp/data/models/feedback_model.dart';
import 'package:music_community_mvp/features/notifications/notification_service.dart';
import '../../features/content/article_controller.dart';
import '../profile/profile_controller.dart';

class AdminController extends GetxController {
  final currentTab = 0
      .obs; // 0: Music, 1: Articles, 2: Comments, 3: Diaries, 4: Users, 5: Feedbacks

  final feedbacks = <FeedbackModel>[].obs;
  final isLoadingFeedbacks = false.obs;

  final users = <Map<String, dynamic>>[].obs;
  final isLoadingUsers = false.obs;

  final reports = <Map<String, dynamic>>[].obs;
  final isLoadingReports = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Double check permission
    final profileController = Get.find<ProfileController>();
    ever(profileController.isAdmin, (isAdmin) {
      if (!isAdmin) {
        Get.offAllNamed('/home');
      }
    });

    // Fetch initial count
    fetchUnresolvedCount();
  }

  void switchTab(int index) {
    currentTab.value = index;
    if (index == 4) {
      // Users tab
      fetchUsers();
    } else if (index == 5) {
      // Feedbacks tab
      fetchFeedbacks();
    } else if (index == 6) {
      // Reports tab
      fetchReports();
    }
  }

  final unresolvedCount = 0.obs;
  final unresolvedReportsCount = 0.obs;

  Future<void> fetchUnresolvedCount() async {
    try {
      final count = await Supabase.instance.client
          .from('feedbacks')
          .count(CountOption.exact)
          .neq('status', 'resolved');
      unresolvedCount.value = count;

      final countReports = await Supabase.instance.client
          .from('reports')
          .count(CountOption.exact)
          .eq('status', 'pending');
      unresolvedReportsCount.value = countReports;
    } catch (e) {
      print("Error fetching unresolved count: $e");
    }
  }

  Future<void> fetchUsers() async {
    try {
      isLoadingUsers.value = true;
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('updated_at', ascending: false);

      users.value = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load users: $e');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> fetchReports() async {
    try {
      isLoadingReports.value = true;
      final response = await Supabase.instance.client
          .from('reports')
          .select('*, reporter:profiles!reporter_id(username, avatar_url)')
          .order('created_at', ascending: false);

      reports.value = List<Map<String, dynamic>>.from(response);

      // Update local count
      unresolvedReportsCount.value = reports
          .where((r) => r['status'] == 'pending')
          .length;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load reports: $e');
    } finally {
      isLoadingReports.value = false;
    }
  }

  Future<void> updateReportStatus(
    String reportId,
    String status, {
    bool showSnackbar = true,
  }) async {
    try {
      await Supabase.instance.client
          .from('reports')
          .update({'status': status})
          .eq('id', reportId);

      // Optimistic update
      final index = reports.indexWhere((r) => r['id'] == reportId);
      if (index != -1) {
        final updated = Map<String, dynamic>.from(reports[index]);
        updated['status'] = status;
        reports[index] = updated;
        reports.refresh();
        // Update count
        if (status != 'pending') {
          // If it was pending, decrement count. But calculating from list is safer.
          unresolvedReportsCount.value = reports
              .where((r) => r['status'] == 'pending')
              .length;
        }
      }
      if (showSnackbar) {
        Get.snackbar('成功', '举报状态已更新');
      }
    } catch (e) {
      if (showSnackbar) {
        Get.snackbar('错误', '更新失败: $e');
      }
    }
  }

  // Enhanced Resolve Logic
  Future<void> resolveReport({
    required String reportId,
    required String action, // 'delete', 'hide', 'ignore'
    required String targetType,
    required String targetId,
    required String message, // System message to violator
  }) async {
    // Show Loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final client = Supabase.instance.client;
      // final adminId = client.auth.currentUser!.id;

      // 1. Find Violator ID
      String? violatorId;
      if (targetType == 'article') {
        final res = await client
            .from('articles')
            .select('user_id')
            .eq('id', targetId)
            .maybeSingle();
        violatorId = res?['user_id'];
      } else if (targetType == 'comment') {
        final res = await client
            .from('article_comments')
            .select('user_id')
            .eq('id', targetId)
            .maybeSingle();
        violatorId = res?['user_id'];
      }

      // 2. Perform Action
      if (action == 'delete') {
        if (targetType == 'article') {
          await client.from('articles').delete().eq('id', targetId);
          // Also remove from local list if exists
          try {
            Get.find<ArticleController>().articles.removeWhere(
              (a) => a.id == targetId,
            );
          } catch (_) {}
        } else if (targetType == 'comment') {
          await client.from('article_comments').delete().eq('id', targetId);
        }
      } else if (action == 'hide' && targetType == 'article') {
        await client
            .from('articles')
            .update({'is_published': false})
            .eq('id', targetId);
        // Remove from public list
        try {
          Get.find<ArticleController>().articles.removeWhere(
            (a) => a.id == targetId,
          );
        } catch (_) {}
      }

      // 3. Send Notification (if violator found)
      if (violatorId != null) {
        await NotificationService.sendNotification(
          recipientId: violatorId,
          type: 'system_warning',
          content: message,
          resourceId:
              targetId, // Might be null/invalid if deleted, but okay for record
        );
      }

      // 4. Update Report Status (Suppress inner snackbar)
      await updateReportStatus(reportId, 'resolved', showSnackbar: false);

      // Close Loading Dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar('处理完成', '操作执行成功');
    } catch (e) {
      // Close Loading Dialog on Error
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      print("Resolve Report Error: $e");
      Get.snackbar('错误', '处理失败: $e');
    }
  }

  Future<void> fetchFeedbacks() async {
    try {
      isLoadingFeedbacks.value = true;
      final response = await Supabase.instance.client
          .from('feedbacks')
          .select('*, profiles(username, avatar_url)')
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      feedbacks.value = data.map((e) => FeedbackModel.fromMap(e)).toList();

      // Update count locally
      unresolvedCount.value = feedbacks
          .where((f) => f.status != 'resolved')
          .length;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load feedbacks: $e');
    } finally {
      isLoadingFeedbacks.value = false;
    }
  }

  Future<void> replyToFeedback(
    String feedbackId,
    String userId,
    String content,
  ) async {
    try {
      // 1. Update status AND reply_content
      await Supabase.instance.client
          .from('feedbacks')
          .update({'status': 'resolved', 'reply_content': content})
          .eq('id', feedbackId);

      // 2. Send Notification
      await NotificationService.sendNotification(
        recipientId: userId,
        type: 'feedback_reply',
        resourceId: feedbackId, // Can be used to context
        content: content,
      );

      // 3. Refresh list
      final index = feedbacks.indexWhere((f) => f.id == feedbackId);
      if (index != -1) {
        // Optimistic update
        // We actually need to reload to full object or just update status locally
        fetchFeedbacks();
      }

      Get.back(); // Close dialog
      Get.snackbar('Success', 'Reply sent successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to reply: $e');
    }
  }

  // --- User Management ---

  Future<void> banUser(String userId, int days) async {
    try {
      final bannedUntil = DateTime.now().add(Duration(days: days));
      await Supabase.instance.client
          .from('profiles')
          .update({
            'status': 'banned',
            'banned_until': bannedUntil.toIso8601String(),
          })
          .eq('id', userId);

      Get.snackbar('成功', '用户已封禁 ${days > 30000 ? "永久" : "$days 天"}');

      // Optimistic Update
      final index = users.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        // Create a new map to ensure reactivity triggers
        final updatedUser = Map<String, dynamic>.from(users[index]);
        updatedUser['status'] = 'banned';
        updatedUser['banned_until'] = bannedUntil.toIso8601String();
        users[index] = updatedUser;
        users.refresh();
      }
    } catch (e) {
      print("Ban Error: $e");
      Get.snackbar('错误', '封禁失败: $e');
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'status': 'active', 'banned_until': null})
          .eq('id', userId);

      Get.snackbar('成功', '用户已解封');

      // Optimistic Update
      final index = users.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        final updatedUser = Map<String, dynamic>.from(users[index]);
        updatedUser['status'] = 'active';
        updatedUser['banned_until'] = null;
        users[index] = updatedUser;
        users.refresh();
      }
    } catch (e) {
      print("Unban Error: $e");
      Get.snackbar('错误', '解封失败: $e');
    }
  }

  Future<void> clearUserContent(String userId) async {
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final client = Supabase.instance.client;

      // 1. Delete Articles (Comments should cascade ideally, but let's delete explicitly if needed)
      // Supabase cascade usually handles comments/likes if setup correctly.
      // Assuming ON DELETE CASCADE on foreign keys.
      await client.from('articles').delete().eq('user_id', userId);

      // 2. Delete Diaries
      await client.from('diaries').delete().eq('user_id', userId);

      // 3. Delete Comments made by user (on others' posts)
      await client.from('comments').delete().eq('user_id', userId);

      // 4. Delete Messages (Sent by user)
      // Note: This leaves the conversation for the other person but missing sender content?
      // Or we delete the message row.
      await client.from('messages').delete().eq('sender_id', userId);

      // 5. Delete Notifications (triggered by user)
      await client.from('notifications').delete().eq('actor_id', userId);

      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('成功', '用户内容已清空');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      print("Clear Content Error: $e");
      Get.snackbar('错误', '清空失败: $e');
    }
  }

  Future<void> resetUserPassword(String userId, String newPassword) async {
    try {
      await Supabase.instance.client.rpc(
        'admin_reset_password',
        params: {'target_user_id': userId, 'new_password': newPassword},
      );
      Get.snackbar('成功', '用户密码已重置');
    } catch (e) {
      print("Reset Password Error: $e");
      Get.snackbar('错误', '重置密码失败: $e');
    }
  }
}
