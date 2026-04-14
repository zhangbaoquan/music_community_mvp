/// 文章互动 Mixin — 处理文章的点赞和收藏操作
///
/// 通过 mixin 模式混入 [ArticleController]，实现职责分离：
/// - 主 Controller 管理文章 CRUD 和列表
/// - 本 Mixin 管理用户互动（点赞/收藏）
///
/// 所有 Supabase 调用通过 [ArticleService] 完成，
/// Controller 层不直接操作数据库。
import 'package:get/get.dart';
import '../../data/models/article.dart';
import '../../data/services/article_service.dart';
import '../profile/profile_controller.dart';

mixin ArticleInteractionMixin on GetxController {
  /// 由主 Controller 提供的依赖
  ArticleService get articleService;
  RxList<Article> get articles;
  String? get currentUserId;

  /// 切换文章点赞状态（乐观更新 + 失败回滚）
  ///
  /// 乐观更新：先更新 UI，再发请求，失败时回滚
  /// 同时发送通知给文章作者（不给自己发）
  Future<void> toggleLike(Article article) async {
    // 权限检查
    if (!await Get.find<ProfileController>().checkActionAllowed('点赞文章')) {
      return;
    }

    final userId = currentUserId;
    if (userId == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    // 保存原始状态，用于失败回滚
    final originalIsLiked = article.isLiked;
    final originalCount = article.likesCount;

    // 乐观更新 UI
    article.isLiked = !originalIsLiked;
    article.likesCount += originalIsLiked ? -1 : 1;
    articles.refresh();

    try {
      if (originalIsLiked) {
        await articleService.unlikeArticle(userId, article.id);
      } else {
        await articleService.likeArticle(userId, article.id);

        // 通知文章作者（不给自己发）
        await articleService.createNotification(
          targetUserId: article.userId,
          actorId: userId,
          type: 'like_article',
          resourceId: article.id,
        );
      }
    } catch (e) {
      // 请求失败，回滚 UI 状态
      article.isLiked = originalIsLiked;
      article.likesCount = originalCount;
      articles.refresh();
      Get.snackbar('服务器错误', '点赞失败: 请检查网络或联系管理员 ($e)',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// 切换文章收藏状态（乐观更新 + 失败回滚）
  Future<void> toggleCollection(Article article) async {
    // 权限检查
    if (!await Get.find<ProfileController>().checkActionAllowed('收藏文章')) {
      return;
    }

    final userId = currentUserId;
    if (userId == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    // 保存原始状态
    final originalIsCollected = article.isCollected;
    final originalCount = article.collectionsCount;

    // 乐观更新 UI
    article.isCollected = !originalIsCollected;
    article.collectionsCount += originalIsCollected ? -1 : 1;
    articles.refresh();

    try {
      if (originalIsCollected) {
        await articleService.uncollectArticle(userId, article.id);
      } else {
        await articleService.collectArticle(userId, article.id);
      }

      // 同步收藏列表到 ProfileController（如果已注册）
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().fetchCollectedArticles();
      }
    } catch (e) {
      // 请求失败，回滚 UI 状态
      article.isCollected = originalIsCollected;
      article.collectionsCount = originalCount;
      articles.refresh();
      Get.snackbar('服务器错误', '收藏失败: 请检查网络或联系管理员 ($e)',
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
