import 'dart:typed_data';
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

      // Fetch status (isLiked/isCollected) for these comments
      // Note: For MVP we do this in loop or parallel, acceptable for small lists.
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null && list.isNotEmpty) {
        await Future.wait(
          list.map((comment) async {
            // check like
            final likeCheck = await _supabase
                .from('comment_likes')
                .select()
                .eq('user_id', userId)
                .eq('comment_id', comment.id)
                .maybeSingle();
            comment.isLiked = likeCheck != null;

            // check collection
            final collectCheck = await _supabase
                .from('comment_collections')
                .select()
                .eq('user_id', userId)
                .eq('comment_id', comment.id)
                .maybeSingle();
            comment.isCollected = collectCheck != null;

            // Fetch count (optional, might be slow if list is long)
            // For MVP let's just fetch count for likes
            final countRes = await _supabase
                .from('comment_likes')
                .count(CountOption.exact)
                .eq('comment_id', comment.id);
            comment.likeCount = countRes;
          }),
        );
      }

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

  // Optimistic Toggle Like
  Future<void> toggleLike(String commentId) async {
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final oldState = comment.isLiked;
    final oldCount = comment.likeCount;

    // Optimistic Update
    comment.isLiked = !oldState;
    comment.likeCount = oldState ? oldCount - 1 : oldCount + 1;
    comments.refresh(); // Trigger Obx

    try {
      final isNowLiked = await _service.toggleLike(commentId);
      // Revert if mismatch (optional, but good practice)
      if (isNowLiked != comment.isLiked) {
        comment.isLiked = isNowLiked;
        comment.likeCount = isNowLiked
            ? oldCount + 1
            : oldCount; // Simplified correction
        comments.refresh();
      }
    } catch (e) {
      // Revert on error
      comment.isLiked = oldState;
      comment.likeCount = oldCount;
      comments.refresh();
      Get.snackbar("操作失败", "点赞失败，请重试");
    }
  }

  // Optimistic Toggle Collect
  Future<void> toggleCollect(String commentId) async {
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final oldState = comment.isCollected;
    // final oldCount = comment.collectionCount; // If we show count

    // Optimistic Update
    comment.isCollected = !oldState;
    comments.refresh();

    try {
      final isNowCollected = await _service.toggleCollection(commentId);
      if (isNowCollected != comment.isCollected) {
        comment.isCollected = isNowCollected;
        comments.refresh();
      }
    } catch (e) {
      comment.isCollected = oldState;
      comments.refresh();
      Get.snackbar("操作失败", "收藏失败，请重试");
    }
  }

  // Delete Comment
  Future<void> deleteComment(String commentId) async {
    // 1. Optimistic Remove
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final removed = comments.removeAt(index);

    try {
      await _service.deleteComment(commentId);
      Get.snackbar("删除成功", "你的故事已随风而去 🍃");
    } catch (e) {
      // Revert
      comments.insert(index, removed);
      Get.snackbar("删除失败", "删除失败，请重试");
    }
  }

  // Upload Image
  Future<String?> uploadImage(Uint8List bytes, String ext) async {
    try {
      return await _service.uploadImage(bytes, ext);
    } catch (e) {
      Get.snackbar("上传失败", "图片上传失败，请重试");
      return null;
    }
  }

  // Update Comment
  Future<void> updateComment(String commentId, String newContent) async {
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final oldContent = comments[index].content;
    comments[index].content = newContent; // Optimistic
    comments.refresh();

    try {
      await _service.updateComment(commentId, newContent);
      Get.snackbar("修改成功", "你的故事已更新 ✨");
    } catch (e) {
      comments[index].content = oldContent; // Revert
      comments.refresh();
      Get.snackbar("修改失败", "修改失败，请重试");
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
