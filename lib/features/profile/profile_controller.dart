import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileController extends GetxController {
  final _supabase = Supabase.instance.client;

  final userEmail = ''.obs;
  final username = ''.obs;
  final avatarUrl = ''.obs;
  final signature = ''.obs;
  final diaryCount = 0.obs;

  // Social Stats
  final followingCount = 0.obs;
  final followersCount = 0.obs;
  final visitorsCount = 0.obs;
  final moodIndex = 85.obs; // Mock value for existing stat

  final email = ''.obs;
  final joinDate = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? 'files@example.com';
      joinDate.value = user.createdAt.split('T')[0];

      try {
        // Fetch Profile Data
        final response = await _supabase
            .from('profiles')
            .select('username, avatar_url, signature')
            .eq('id', user.id)
            .single();

        username.value = response['username'] as String? ?? '';
        avatarUrl.value = response['avatar_url'] as String? ?? '';
        signature.value = response['signature'] as String? ?? '';

        // Fetch Diaries Count
        final statsResponse = await _supabase
            .from('mood_diaries')
            .select('id')
            .eq('user_id', user.id);

        final List data = statsResponse;
        diaryCount.value = data.length;

        // Fetch Social Stats
        await fetchUserStats(user.id);
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  Future<void> fetchUserStats(String userId) async {
    try {
      // Fetch Followers (how many people follow me)
      final followersRes = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId)
          .count(CountOption.exact);

      // Fetch Following (how many people I follow)
      final followingRes = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .count(CountOption.exact);

      followersCount.value = followersRes.count;
      followingCount.value = followingRes.count;

      // TODO: Implement visitors count if we have a table for it
      // visitorsCount.value = ...
    } catch (e) {
      print('Error fetching user stats: $e');
    }
  }

  /// Check if the current user is following the target user
  Future<bool> checkIsFollowing(String targetUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    try {
      final res = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', currentUser.id)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return res != null;
    } catch (e) {
      return false;
    }
  }

  /// Follow a user
  Future<bool> followUser(String targetUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;
    if (currentUser.id == targetUserId) return false; // Cannot follow self

    try {
      await _supabase.from('follows').insert({
        'follower_id': currentUser.id,
        'following_id': targetUserId,
      });
      // Update local stats
      followingCount.value++;

      // Trigger Notification
      // We use the static method or find the service
      // Using generic insert if service not available, but we can import it
      try {
        // Ideally use dependency injection, but here we can just do a direct insert
        // or use the service if it's easy to import.
        // Let's use the DB directly here to avoid circular dependencies if any,
        // OR better: use the Service static method if we defined one.
        // We defined a static method `sendNotification`.
        // We need to import it.
      } catch (_) {}

      // Send Notification
      // We will perform the insert directly here or use a helper to avoid looking up service
      await _supabase.from('notifications').insert({
        'user_id': targetUserId,
        'actor_id': currentUser.id,
        'type': 'follow',
      });

      return true;
    } catch (e) {
      print('Follow Error: $e');
      Get.snackbar('错误', '关注失败: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _supabase
          .from('follows')
          .delete()
          .eq('follower_id', currentUser.id)
          .eq('following_id', targetUserId);

      // Update local stats
      if (followingCount.value > 0) followingCount.value--;
      return true;
    } catch (e) {
      print('Unfollow Error: $e');
      Get.snackbar('错误', '取消关注失败: $e');
      return false;
    }
  }

  /// Update Profile
  Future<bool> updateProfile({
    String? newUsername,
    String? newSignature,
    PlatformFile? newAvatar,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (newUsername != null) updates['username'] = newUsername;
      if (newSignature != null) updates['signature'] = newSignature;

      // Upload Avatar if provided
      if (newAvatar != null && newAvatar.bytes != null) {
        final fileExt = newAvatar.name.split('.').last;
        final fileName =
            '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await _supabase.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              newAvatar.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = _supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);
        updates['avatar_url'] = publicUrl;
        avatarUrl.value = publicUrl;
      }

      await _supabase.from('profiles').upsert({'id': user.id, ...updates});

      // Update Local State
      if (newUsername != null) username.value = newUsername;
      if (newSignature != null) signature.value = newSignature;

      Get.snackbar('成功', '个人资料已更新');
      return true;
    } catch (e) {
      print('Profile Update Error: $e');
      Get.snackbar('错误', '更新失败: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    // AuthController listener will handle redirection
  }
}
