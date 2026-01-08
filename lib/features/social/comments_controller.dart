import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../player/player_controller.dart';
import 'comment_model.dart';
import 'comment_service.dart';

class CommentsController extends GetxController {
  final _service = CommentService();
  final PlayerController _playerCtrl = Get.find();
  final _supabase = Supabase.instance.client;

  final comments = <Comment>[].obs;
  final isLoading = false.obs;
  final isPosting = false.obs;

  RealtimeChannel? _subscription;

  @override
  void onInit() {
    super.onInit();
    // Listen to song changes
    ever(_playerCtrl.currentMood, (mood) {
      if (mood.isNotEmpty) {
        _loadCommentsForMood(mood);
      }
    });

    // Initial load if song is already playing
    if (_playerCtrl.currentMood.value.isNotEmpty) {
      _loadCommentsForMood(_playerCtrl.currentMood.value);
    }
  }

  Future<void> _loadCommentsForMood(String mood) async {
    isLoading.value = true;
    comments.clear();

    // Unsubscribe previous
    if (_subscription != null) {
      await _supabase.removeChannel(_subscription!);
      _subscription = null;
    }

    try {
      // Fetch initial
      final list = await _service.fetchComments(mood);
      comments.assignAll(list);

      // Subscribe realtime
      _subscription = _service.subscribeToComments(mood, (newComment) {
        // Insert at top if not already there (dedupe just in case)
        if (!comments.any((c) => c.id == newComment.id)) {
          comments.insert(0, newComment);
        }
      });
    } catch (e) {
      print("Error loading comments: $e");
      // Don't snackbar on load error to avoid spamming usage
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> postComment(String content) async {
    if (content.trim().isEmpty) return;
    final mood = _playerCtrl.currentMood.value;
    if (mood.isEmpty) return;

    isPosting.value = true;
    try {
      // Derive Nickname
      final email = _supabase.auth.currentUser?.email ?? 'Anonymous';
      final nickname = email.split('@')[0];

      await _service.postComment(
        songId: mood,
        content: content,
        userNickname: nickname,
      );
      // No need to add manually, Realtime will catch it
      Get.back(); // Close sheet
      Get.snackbar("发射成功", "你的故事已送达星空 ✨");
    } catch (e) {
      print("Post error: $e");
      Get.snackbar("发送失败", "网络开小差了，请重试");
    } finally {
      isPosting.value = false;
    }
  }

  @override
  void onClose() {
    if (_subscription != null) {
      _supabase.removeChannel(_subscription!);
    }
    super.onClose();
  }
}
