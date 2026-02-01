import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/badge.dart';
import '../gamification/badge_service.dart';

class ProfileController extends GetxController {
  final _supabase = Supabase.instance.client;

  final userEmail = ''.obs;
  final username = ''.obs;
  final avatarUrl = ''.obs;
  final signature = ''.obs;
  final isAdmin = false.obs; // NEW: Admin status
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
            .select(
              'username, avatar_url, signature, is_admin',
            ) // Updated selection
            .eq('id', user.id)
            .single();

        username.value = response['username'] as String? ?? '';
        avatarUrl.value = response['avatar_url'] as String? ?? '';
        signature.value = response['signature'] as String? ?? '';
        isAdmin.value =
            response['is_admin'] as bool? ?? false; // Update isAdmin

        // Fetch Diaries Count
        final statsResponse = await _supabase
            .from('mood_diaries')
            .select('id')
            .eq('user_id', user.id);

        final List data = statsResponse;
        diaryCount.value = data.length;

        // Fetch Social Stats
        await fetchUserStats(user.id);

        // Fetch Badges
        await fetchBadges(user.id);
      } catch (e) {
        print('Error loading profile: $e');
      }
    }
  }

  // Badges
  final earnedBadges = <BadgeModel>[].obs;

  Future<void> fetchBadges(String userId) async {
    final badgeService = Get.put(BadgeService());
    earnedBadges.value = await badgeService.getEarnedBadges(userId);
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

      // Fetch Visitors Count
      final visitorsRes = await _supabase
          .from('profile_visits')
          .select('visitor_id')
          .eq('visited_id', userId)
          .count(CountOption.exact);

      followersCount.value = followersRes.count;
      followingCount.value = followingRes.count;
      visitorsCount.value = visitorsRes.count;
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

  // --- Phase 6.3: User Discovery ---

  Future<List<Map<String, dynamic>>> fetchFollowersList(String userId) async {
    try {
      final res = await _supabase
          .from('follows')
          .select(
            'follower_id, profiles!follows_follower_id_fkey(username, avatar_url, signature)',
          ) // Ensure foreign key is used
          .eq('following_id', userId);

      // Res is List<Map<String, dynamic>>
      // Structure: [{'follower_id': '...', 'profiles': {'username': '...', ...}}]
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error fetching followers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchFollowingList(String userId) async {
    try {
      final res = await _supabase
          .from('follows')
          .select(
            'following_id, profiles!follows_following_id_fkey(username, avatar_url, signature)',
          )
          .eq('follower_id', userId);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error fetching following: $e');
      return [];
    }
  }

  /// Fetch public profile data for a stranger
  Future<Map<String, dynamic>?> getPublicProfile(String userId) async {
    try {
      final profileRes = await _supabase
          .from('profiles')
          .select('username, avatar_url, signature')
          .eq('id', userId)
          .single();

      // Fetch counts manually since we don't have triggers/computed columns yet
      final followerCount = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId)
          .count();

      final followingCount = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId)
          .count();

      final diaryCount = await _supabase
          .from('mood_diaries')
          .select('id')
          .eq('user_id', userId)
          .count();

      return {
        ...profileRes,
        'followers_count': followerCount.count,
        'following_count': followingCount.count,
        'diary_count': diaryCount.count,
      };
    } catch (e) {
      print('Error fetching public profile: $e');
      return null;
    }
  }

  // --- Phase 6.4: Visitor System ---

  /// Record a visit to a user's profile
  Future<void> recordVisit(String visitedId) async {
    final user = _supabase.auth.currentUser;
    // 1. Must be logged in
    if (user == null) return;
    // 2. Don't record visiting yourself
    if (user.id == visitedId) return;

    try {
      // Upsert visit record
      // Unique constraint on (visitor_id, visited_id) will handle conflict
      // We just update 'visited_at' to now()
      await _supabase.from('profile_visits').upsert({
        'visitor_id': user.id,
        'visited_id': visitedId,
        'visited_at': DateTime.now().toIso8601String(),
      }, onConflict: 'visitor_id, visited_id');
    } catch (e) {
      print('Error recording visit: $e');
      // Fail silently, not critical
    }
  }

  /// Fetch visitors for the current user (or any user if policy allows)
  Future<List<Map<String, dynamic>>> fetchVisitors() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _supabase
          .from('profile_visits')
          .select(
            'visitor_id, visited_at, profiles!profile_visits_visitor_id_fkey(username, avatar_url, signature)',
          )
          .eq('visited_id', user.id)
          .order('visited_at', ascending: false);

      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error fetching visitors: $e');
      return [];
    }
  }

  /// Get total visitor count if needed for stats
  Future<int> fetchVisitorCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;
    try {
      final res = await _supabase
          .from('profile_visits')
          .select('visitor_id')
          .eq('visited_id', user.id)
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      return 0;
    }
  }
}
