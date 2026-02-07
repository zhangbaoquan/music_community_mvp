import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafetyService extends GetxService {
  // Simple in-memory rate limiting map: ActionKey -> LastTime
  final Map<String, DateTime> _lastActionTimes = {};

  // Example sensitive words list (Should be fetched from remote config ideally)
  final List<String> _blockedKeywords = [
    '傻逼',
    '死全家',
    '操你妈',
    '滚蛋',
    '废物',
    '垃圾',
    '脑残',
    '智障',
    '去死',
    'sb',
    'nmb',
    'cnm',
    'fuck',
    'shit',
  ];

  /// Initialize service
  Future<SafetyService> init() async {
    return this;
  }

  /// Check if content contains sensitive words
  /// Returns `true` if content is safe.
  /// Throws exception with message if unsafe.
  bool validateContent(String text) {
    if (text.isEmpty) return true;

    for (final word in _blockedKeywords) {
      if (text.contains(word)) {
        Get.snackbar(
          '内容违规',
          '包含敏感词汇: "$word"，请修改后重试',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }
    return true;
  }

  /// Check if user is posting too frequently
  /// [actionKey]: Unique identifier for the action type (e.g. 'post_article', 'add_comment')
  /// [cooldownSeconds]: Minimum seconds between actions. Default 60s for posts.
  /// Returns `true` if allow, `false` if blocked (and shows toast).
  bool checkRateLimit(String actionKey, {int cooldownSeconds = 60}) {
    final now = DateTime.now();
    final lastTime = _lastActionTimes[actionKey];

    if (lastTime != null) {
      final difference = now.difference(lastTime).inSeconds;
      if (difference < cooldownSeconds) {
        final remaining = cooldownSeconds - difference;
        Get.snackbar(
          '操作频繁',
          '请休息一下，$remaining 秒后再试',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    }

    _lastActionTimes[actionKey] = now;
    return true;
  }

  /// Combined Check: Validate Content AND Rate Limit
  bool canPost(String content, String actionKey, {int cooldownSeconds = 60}) {
    if (!validateContent(content)) return false;
    if (!checkRateLimit(actionKey, cooldownSeconds: cooldownSeconds))
      return false;
    return true;
  }

  /// Report content
  Future<bool> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      Get.snackbar('错误', '请先登录');
      return false;
    }

    try {
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': user.id,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'description': description,
      });
      Get.snackbar(
        '举报成功',
        '感谢您的反馈，我们会尽快处理',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } catch (e) {
      print('Report Error: $e');
      Get.snackbar('举报失败', '请稍后重试');
      return false;
    }
  }
}
