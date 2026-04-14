/// 文章控制器 — 管理文章列表、CRUD 和发布
///
/// 职责划分：
/// - 本文件：文章查询/发布/更新/删除 + 列表状态管理
/// - [ArticleInteractionMixin]：点赞/收藏
/// - [ArticleCommentMixin]：评论系统
///
/// 所有 Supabase 调用通过 [ArticleService] 完成，
/// Controller 不直接操作数据库。
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/article.dart';
import '../../data/services/article_service.dart';
import '../gamification/badge_service.dart';
import '../profile/profile_controller.dart';
import '../safety/safety_service.dart';
import 'article_interaction_mixin.dart';
import 'article_comment_mixin.dart';

class ArticleController extends GetxController
    with ArticleInteractionMixin, ArticleCommentMixin {
  /// 数据服务层 — 所有 Supabase 操作的唯一入口
  @override
  final ArticleService articleService = ArticleService();

  final _supabase = Supabase.instance.client;

  // ============================================================
  // 状态变量
  // ============================================================

  /// 文章列表加载状态
  final isLoading = false.obs;

  /// 文章发布/更新时的上传状态
  final isUploading = false.obs;

  /// 公开文章列表（首页 Feed 流）
  @override
  final articles = <Article>[].obs;

  /// 当前用户的文章列表（个人中心使用）
  final userArticles = <Article>[].obs;

  /// 当前登录用户 ID（供 Mixin 使用）
  @override
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void onInit() {
    super.onInit();
    fetchArticles();

    // 监听登录/登出事件，刷新数据
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        _clearArticlesState();
      } else if (data.event == AuthChangeEvent.signedIn) {
        // 重新登录后刷新，确保点赞/收藏状态与新用户匹配
        fetchArticles();
      }
    });
  }

  /// 清空文章缓存（登出时调用）
  void _clearArticlesState() {
    userArticles.clear();
    articles.clear();
  }

  // ============================================================
  // 文章查询
  // ============================================================

  /// 获取所有已发布文章，并填充当前用户的互动状态
  Future<void> fetchArticles() async {
    try {
      isLoading.value = true;

      // 1. 获取文章列表
      final loadedArticles = await articleService.fetchArticles();

      // 2. 填充当前用户的互动状态（点赞/收藏）
      final userId = currentUserId;
      if (userId != null && loadedArticles.isNotEmpty) {
        final articleIds = loadedArticles.map((a) => a.id).toList();

        // 批量查询点赞和收藏状态（并行执行提高性能）
        final results = await Future.wait([
          articleService.fetchMyLikedArticleIds(userId, articleIds),
          articleService.fetchMyCollectedArticleIds(userId, articleIds),
        ]);

        final likedIds = results[0];
        final collectedIds = results[1];

        // 合并互动状态到文章对象
        for (var article in loadedArticles) {
          article.isLiked = likedIds.contains(article.id);
          article.isCollected = collectedIds.contains(article.id);
        }
      }

      articles.value = loadedArticles;
    } catch (e) {
      Get.snackbar('错误', '加载文章失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取单篇文章详情（用于深链接场景）
  ///
  /// 自动填充当前用户的互动状态
  Future<Article?> fetchArticleDetails(String id) async {
    try {
      isLoading.value = true;

      final article = await articleService.fetchArticleDetail(id);

      // 填充互动状态
      final userId = currentUserId;
      if (userId != null) {
        article.isLiked = await articleService.isArticleLiked(userId, id);
        article.isCollected =
            await articleService.isArticleCollected(userId, id);
      }
      return article;
    } catch (e) {
      print('[文章] 获取文章详情失败: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// 获取指定用户的文章列表
  Future<void> fetchUserArticles(String userId) async {
    try {
      userArticles.value = await articleService.fetchUserArticles(userId);
    } catch (e) {
      print('[文章] 获取用户文章失败: $e');
    }
  }

  // ============================================================
  // 文章 CRUD
  // ============================================================

  /// 删除文章
  Future<bool> deleteArticle(String articleId) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('删除文章')) {
      return false;
    }
    try {
      await articleService.deleteArticle(articleId);

      // 从本地缓存中移除
      articles.removeWhere((a) => a.id == articleId);
      userArticles.removeWhere((a) => a.id == articleId);
      return true;
    } catch (e) {
      print('[文章] 删除文章失败: $e');
      return false;
    }
  }

  /// 更新文章
  Future<bool> updateArticle({
    required String articleId,
    required String title,
    required String summary,
    required List<dynamic> contentJson,
    PlatformFile? coverFile,
    String? bgmSongId,
    String type = 'original',
    List<String> tags = const [],
  }) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('更新文章')) {
      return false;
    }

    // 内容安全检查
    final safetyService = Get.find<SafetyService>();
    if (!safetyService.validateContent(title) ||
        !safetyService.validateContent(summary)) {
      return false;
    }

    try {
      isUploading.value = true;

      // 构建更新数据
      final updates = <String, dynamic>{
        'title': title,
        'summary': summary,
        'content': contentJson,
        'bgm_song_id': bgmSongId,
        'type': type,
        'tags': tags,
        'is_published': true,
      };

      // 如果有新封面图，先上传
      if (coverFile != null) {
        final userId = currentUserId!;
        final fileExt = coverFile.name.split('.').last;
        updates['cover_url'] = await articleService.uploadCoverImage(
          userId: userId,
          fileBytes: coverFile.bytes!,
          fileExtension: fileExt,
        );
      }

      await articleService.updateArticle(articleId, updates);

      // 刷新文章列表
      await fetchArticles();
      if (currentUserId != null) fetchUserArticles(currentUserId!);

      return true;
    } catch (e) {
      print('[文章] 更新文章失败: $e');
      Get.snackbar('更新失败', '错误信息: $e',
          duration: const Duration(seconds: 5));
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  /// 发布新文章
  Future<bool> publishArticle({
    required String title,
    required String summary,
    required List<dynamic> contentJson,
    PlatformFile? coverFile,
    String? bgmSongId,
    String type = 'original',
    List<String> tags = const [],
  }) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('发布文章')) {
      return false;
    }

    // 内容安全检查
    final safetyService = Get.find<SafetyService>();
    if (!safetyService.validateContent(title) ||
        !safetyService.validateContent(summary)) {
      return false;
    }
    // 发布频率限制（60 秒冷却）
    if (!safetyService.checkRateLimit('publish_article')) {
      return false;
    }

    try {
      isUploading.value = true;
      final userId = currentUserId;
      if (userId == null) return false;

      // 上传封面图（可选）
      String? coverUrl;
      if (coverFile != null) {
        final fileExt = coverFile.name.split('.').last;
        coverUrl = await articleService.uploadCoverImage(
          userId: userId,
          fileBytes: coverFile.bytes!,
          fileExtension: fileExt,
        );
      }

      // 构建文章对象并插入数据库
      final article = Article(
        id: '', // 由数据库自动生成
        userId: userId,
        title: title,
        summary: summary,
        coverUrl: coverUrl,
        content: contentJson,
        createdAt: DateTime.now(),
        bgmSongId: bgmSongId,
        type: type,
        tags: tags,
      );

      await articleService.insertArticle(article.toMap()..remove('id'));

      // 刷新文章列表
      fetchArticles();
      fetchUserArticles(userId);

      // 检查成就徽章
      Get.put(BadgeService()).checkArticleMilestones();

      return true;
    } catch (e) {
      print('[文章] 发布文章失败: $e');
      Get.snackbar('发布失败', '错误信息: $e',
          duration: const Duration(seconds: 5));
      return false;
    } finally {
      isUploading.value = false;
    }
  }
}
