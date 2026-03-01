import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/badge.dart';
import '../../data/models/article.dart'; // Import Article Model
import '../../data/services/log_service.dart';
import '../gamification/badge_service.dart';

class ProfileController extends GetxController {
  final _supabase = Supabase.instance.client;
  final LogService _logService = Get.find<LogService>();

  final userEmail = ''.obs;
  final username = ''.obs;
  final avatarUrl = ''.obs;
  final signature = ''.obs;
  final isAdmin = false.obs; // NEW: Admin status
  final diaryCount = 0.obs;

  // Ban Status
  final status = 'active'.obs;
  final bannedUntil = Rx<DateTime?>(null);

  bool get isBanned {
    if (status.value != 'banned') return false;
    // If banned_until is null, assume permanent ban
    // If it has a date, check if it's in the future
    if (bannedUntil.value == null) return true;
    final until = bannedUntil.value;
    if (until == null) return false;
    return until.isAfter(DateTime.now());
  }

  bool get isGuest => _supabase.auth.currentUser == null;

  Future<bool> requireLogin() async {
    if (!isGuest) return true;
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('提示'),
        content: const Text('该功能需要登录后才能使用，是否前往登录？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('去登录'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      Get.toNamed('/login');
    }
    return false;
  }

  Future<bool> checkActionAllowed(String actionName) async {
    if (await requireLogin() == false) return false;

    if (isBanned) {
      Get.snackbar(
        '当前处于封禁中',
        '您已被封禁，不能进行此操作 ($actionName)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  // Social Stats
  final followingCount = 0.obs;
  final followersCount = 0.obs;
  final visitorsCount = 0.obs;
  final moodIndex = 85.obs; // Mock value

  // New: Received Stats (Passive interactions)
  final receivedLikesCount = 0.obs;
  final receivedCommentsCount = 0.obs;
  final receivedCollectionsCount = 0.obs;

  // New: Collected Articles
  final collectedArticles = <Article>[].obs;

  final email = ''.obs;
  final joinDate = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    _logService.uploadLog(content: 'loadProfile');
    final user = _supabase.auth.currentUser;
    if (user != null) {
      userEmail.value = user.email ?? '';
      final createdAt = user.createdAt;
      joinDate.value = createdAt.contains('T')
          ? createdAt.split('T')[0]
          : createdAt;

      try {
        // Fetch Profile Data
        final response = await _supabase
            .from('profiles')
            .select(
              'username, avatar_url, signature, is_admin, status, banned_until',
            )
            .eq('id', user.id)
            .single();

        username.value = response['username'] as String? ?? '';
        avatarUrl.value = response['avatar_url'] as String? ?? '';
        signature.value = response['signature'] as String? ?? '';
        isAdmin.value = response['is_admin'] as bool? ?? false;

        // Ban Info
        status.value = response['status'] as String? ?? 'active';
        final bannedUntilStr = response['banned_until'] as String?;
        if (bannedUntilStr != null) {
          bannedUntil.value = DateTime.tryParse(bannedUntilStr);
        } else {
          bannedUntil.value = null;
        }

        // Fetch Diaries Count
        final statsResponse = await _supabase
            .from('mood_diaries')
            .select('id')
            .eq('user_id', user.id);

        if (statsResponse == null) {
          diaryCount.value = 0;
        } else {
          final List data = statsResponse as List<dynamic>;
          diaryCount.value = data.length;
        }

        // Fetch Social Stats (Active)
        await fetchUserStats(user.id);

        // Fetch Received Stats (Passive)
        await fetchUserReceivedStats(user.id);

        // Fetch Collected Articles
        await fetchCollectedArticles();

        // Fetch Badges
        await fetchBadges(user.id);
      } catch (e) {
        print('Error loading profile: $e');
        _logService.uploadLog(content: 'Error loading profile: $e');
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
          .eq('following_id', userId);

      // Fetch Following (how many people I follow)
      final followingRes = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);

      // Fetch Visitors Count
      final visitorsRes = await _supabase
          .from('profile_visits')
          .select('visitor_id')
          .eq('visited_id', userId);

      followersCount.value = (followersRes as List).length;
      followingCount.value = (followingRes as List).length;
      visitorsCount.value = (visitorsRes as List).length;
    } catch (e, stack) {
      print('Error fetching user stats: $e');
      print('Stack Trace: $stack');
      _logService.uploadLog(content: 'Error fetching user stats: $e\n$stack');
    }
  }

  /// Fetch stats received by the user (Likes, Comments, Collections on their articles)
  Future<void> fetchUserReceivedStats(String userId) async {
    try {
      final res = await _supabase.rpc(
        'get_user_article_stats',
        params: {'target_user_id': userId},
      );
      // res is { "likes_received": int, ... }
      if (res != null) {
        receivedLikesCount.value = res['likes_received'] as int? ?? 0;
        receivedCommentsCount.value = res['comments_received'] as int? ?? 0;
        receivedCollectionsCount.value =
            res['collections_received'] as int? ?? 0;
      }
    } catch (e) {
      print('Error fetching received stats: $e');
      _logService.uploadLog(content: 'Error fetching received stats: $e');
    }
  }

  /// Fetch Articles collected by the current user
  Future<void> fetchCollectedArticles() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Join article_collections -> articles -> profiles
      // We need the article details.
      final response = await _supabase
          .from('article_collections')
          .select(
            'articles(*, profiles(username, avatar_url), songs(title), likes:article_likes(count), collections:article_collections(count), comments:article_comments(count))',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (response == null) {
        collectedArticles.value = [];
        return;
      }
      final data = response as List<dynamic>;
      // Map inner article object
      collectedArticles.value = data
          .map(
            (e) =>
                e['articles'] != null ? Article.fromMap(e['articles']) : null,
          )
          .whereType<Article>()
          .toList();

      // We should also set isCollected = true for these since they are in the collection
      for (var article in collectedArticles) {
        article.isCollected = true;
      }
    } catch (e) {
      print('Error fetching collected articles: $e');
      _logService.uploadLog(content: 'Error fetching collected articles: $e');
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
    if (!await checkActionAllowed('关注用户')) return false;

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
    } catch (e, stack) {
      print('Follow Error: $e');
      print('Stack Trace: $stack');
      Get.snackbar('错误', '关注失败: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String targetUserId) async {
    if (!await checkActionAllowed('取消关注')) return false;

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
    if (!await checkActionAllowed('编辑资料')) return false;

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
      _logService.uploadLog(content: 'res: ${res.length}');
      // Res is List<Map<String, dynamic>>
      // Structure: [{'follower_id': '...', 'profiles': {'username': '...', ...}}]
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('Error fetching followers: $e');
      _logService.uploadLog(content: 'Error fetching followers: $e');
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
      _logService.uploadLog(content: 'Error fetching following: $e');
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
      final followersRes = await _supabase
          .from('follows')
          .select('follower_id')
          .eq('following_id', userId);
      final followingRes = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', userId);
      final articlesRes = await _supabase
          .from('articles')
          .select('id')
          .eq('user_id', userId)
          .eq('is_published', true);

      return {
        ...profileRes,
        'followers': (followersRes as List).length,
        'following': (followingRes as List).length,
        'diary': (articlesRes as List).length,
      };
    } catch (e) {
      print('Error fetching public profile: $e');
      _logService.uploadLog(content: 'Error fetching public profile: $e');
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
      _logService.uploadLog(content: 'Error recording visit: $e');
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
      _logService.uploadLog(content: 'Error fetching visitors: $e');
      return [];
    }
  }

  /// Get total visitor count if needed for stats
  Future<int> fetchVisitorCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;
    try {
      final visitorsRes = await _supabase
          .from('profile_visits')
          .select('visitor_id')
          .eq('visited_id', user.id);

      return (visitorsRes as List).length;
    } catch (e) {
      return 0;
    }
  }
}
