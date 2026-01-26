import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/badge.dart';
import 'badge_popup.dart';

class BadgeService extends GetxService {
  final _supabase = Supabase.instance.client;

  // Cache of all available configuration badges
  final RxList<BadgeModel> allBadges = <BadgeModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final response = await _supabase.from('badges').select();
      final List<dynamic> data = response;
      allBadges.value = data.map((e) => BadgeModel.fromMap(e)).toList();
    } catch (e) {
      print("Error loading badges: $e");
    }
  }

  /// Check for Article Milestones (Call this after publishing an article)
  Future<void> checkArticleMilestones() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Ensure badges are loaded
    if (allBadges.isEmpty) {
      await _loadBadges();
    }

    try {
      // 1. Get current count
      final count = await _supabase
          .from('articles')
          .count(CountOption.exact)
          .eq('author_id', user.id);

      // 2. Check against 'article_count' badges
      // Use logic to check all milestones up to this count?
      // Or just check relevant ones.
      _checkAndAward(user.id, 'article_count', count);
    } catch (e) {
      print("Error checking article milestones: $e");
    }
  }

  /// Check for Comment Milestones (Call this after commenting)
  Future<void> checkCommentMilestones() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Ensure badges are loaded
    if (allBadges.isEmpty) {
      await _loadBadges();
    }

    try {
      // 1. Get current count
      final count = await _supabase
          .from('comments')
          .count(CountOption.exact)
          .eq('user_id', user.id);

      // 2. Check against 'comment_count' badges
      _checkAndAward(user.id, 'comment_count', count);
    } catch (e) {
      print("Error checking comment milestones: $e");
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

    for (final badge in candidates) {
      // Check if already owned
      final ownedRes = await _supabase
          .from('user_badges')
          .select()
          .eq('user_id', userId)
          .eq('badge_id', badge.id)
          .maybeSingle();

      if (ownedRes == null) {
        // Not owned yet, award it!
        await _awardBadge(userId, badge);
      }
    }
  }

  Future<void> _awardBadge(String userId, BadgeModel badge) async {
    try {
      await _supabase.from('user_badges').insert({
        'user_id': userId,
        'badge_id': badge.id,
      });

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
