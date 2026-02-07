import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:music_community_mvp/data/models/feedback_model.dart';
import 'package:music_community_mvp/features/notifications/notification_service.dart';
import '../profile/profile_controller.dart';

class AdminController extends GetxController {
  final currentTab = 0
      .obs; // 0: Music, 1: Articles, 2: Comments, 3: Diaries, 4: Users, 5: Feedbacks

  final feedbacks = <FeedbackModel>[].obs;
  final isLoadingFeedbacks = false.obs;

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
  }

  void switchTab(int index) {
    currentTab.value = index;
    if (index == 5) {
      fetchFeedbacks();
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
      // 1. Update status
      await Supabase.instance.client
          .from('feedbacks')
          .update({'status': 'resolved'})
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
}
