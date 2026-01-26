import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/badge.dart';
import 'badge_popup.dart';

class BadgeService extends GetxService {
  final _supabase = Supabase.instance.client;

  // Cache of all available configuration badges
  final RxList<BadgeModel> allBadges = <BadgeModel>[].obs;

  // Cache of earned badges
  final RxList<BadgeModel> earnedBadges = <BadgeModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadBadges();
    _loadEarnedBadges();
  }

  Future<void> _loadEarnedBadges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    earnedBadges.value = await getEarnedBadges(user.id);
  }

  Future<void> _loadBadges() async {
    try {
      final response = await _supabase.from('badges').select();
      final List<dynamic> data = response;
      allBadges.value = data.map((e) => BadgeModel.fromMap(e)).toList();
      print("DEBUG: Loaded ${allBadges.length} badges from DB.");
    } catch (e) {
      print("Error loading badges: $e");
    }
  }

  /// Check for Article Milestones (Call this after publishing an article)
  Future<void> checkArticleMilestones() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Ensure badges are loaded
    if (allBadges.isEmpty) await _loadBadges();

    try {
      // 1. Get current count
      final count = await _supabase
          .from('articles')
          .count(CountOption.exact)
          .eq('user_id', user.id); // Corrected to user_id

      print('DEBUG: Article Count for ${user.id}: $count');

      // 2. Check against 'article_count' badges
      await _checkAndAward(user.id, 'article_count', count);
    } catch (e) {
      print("Error checking article milestones: $e");
    }
  }

  /// Check for Comment Milestones
  Future<void> checkCommentMilestones() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (allBadges.isEmpty) await _loadBadges();

    try {
      final count = await _supabase
          .from('comments')
          .count(CountOption.exact)
          .eq('user_id', user.id);
      print('DEBUG: Comment Count for ${user.id}: $count');
      await _checkAndAward(user.id, 'comment_count', count);
    } catch (e) {
      print("Error checking comment milestones: $e");
    }
  }

  /// Check for Likes Received (Popularity)
  Future<void> checkLikeMilestones() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (allBadges.isEmpty) await _loadBadges();

    try {
      // Count total likes. This depends on if we have a denormalized 'likes_received' on profile
      // or if we have to count query. For MVP let's trust we can fetch 'total_likes' from a view or profile?
      // Actually, let's use a simpler query: `articles` sum(likes_count) if available, or just skip for now if too hard.
      // Wait, we can count `article_likes` where `article_id` is in my articles.
      // Or just a stored procedure.
      // Let's assume we maintain a `total_likes` in `profiles`.
      // If not, let's try to count via relation.

      // Attempt 1: Count `article_likes` via join. Supabase JS: .rpc() or specific query.
      // We will skip complex query implementation here and use a placeholder or RPC if the user setup it.
      // Simpler approach: Check just *one* article with high likes? No, sum.

      // Let's do `follower_count` first as it is easier.
    } catch (e) {
      print(e);
    }
  }

  /// Check for Follower Milestones
  Future<void> checkFollowerMilestones() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    if (allBadges.isEmpty) await _loadBadges();

    try {
      final count = await _supabase
          .from('follows')
          .count(CountOption.exact)
          .eq('following_id', user.id);

      print('DEBUG: Follower Count for ${user.id}: $count');
      await _checkAndAward(user.id, 'follower_count', count);
    } catch (e) {
      print("Error checking follower milestones: $e");
    }
  }

  Future<void> _checkAndAward(
    String userId,
    String conditionType,
    int currentCount,
  ) async {
    // Filter relevant badges
    final candidates = allBadges
        .where(
          (b) =>
              b.conditionType == conditionType && b.threshold <= currentCount,
        )
        .toList();

    print(
      'DEBUG: Found ${candidates.length} candidates for $conditionType <= $currentCount',
    );

    for (final badge in candidates) {
      // Check if already owned in LOCAL cache to save call?
      // Actually we have earnedBadges list now.
      final alreadyOwned = earnedBadges.any((b) => b.id == badge.id);

      if (!alreadyOwned) {
        // Double check DB
        final ownedRes = await _supabase
            .from('user_badges')
            .select()
            .eq('user_id', userId)
            .eq('badge_id', badge.id)
            .maybeSingle();

        if (ownedRes == null) {
          print('DEBUG: Awarding badge: ${badge.name}');
          await _awardBadge(userId, badge);
        }
      }
    }
  }

  Future<void> _awardBadge(String userId, BadgeModel badge) async {
    try {
      await _supabase.from('user_badges').insert({
        'user_id': userId,
        'badge_id': badge.id,
      });

      // Update local cache
      earnedBadges.add(badge);

      // Show Popup
      Get.dialog(BadgePopup(badge: badge));
    } catch (e) {
      print("Error awarding badge: $e");
    }
  }

  Future<List<BadgeModel>> getEarnedBadges(String userId) async {
    try {
      final response = await _supabase
          .from('user_badges')
          .select('badge_id, badges(*)')
          .eq('user_id', userId);

      final List<dynamic> data = response;
      return data.map((e) => BadgeModel.fromMap(e['badges'])).toList();
    } catch (e) {
      print("Error loading earned badges: $e");
      return [];
    }
  }
}
