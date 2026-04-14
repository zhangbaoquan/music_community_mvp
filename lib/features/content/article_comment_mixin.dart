/// 文章评论 Mixin — 处理文章评论的查询、发布和点赞
///
/// 通过 mixin 模式混入 [ArticleController]，实现职责分离：
/// - 主 Controller 管理文章 CRUD 和列表
/// - 本 Mixin 管理评论系统（查询、发布、点赞、楼中楼）
///
/// 评论采用树形结构：
/// - 顶层评论（parentId == null）作为根节点
/// - 回复评论（parentId != null）挂在父评论的 replies 列表下
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/article.dart';
import '../../data/models/article_comment.dart';
import '../../data/services/article_service.dart';
import '../gamification/badge_service.dart';
import '../profile/profile_controller.dart';
import '../safety/safety_service.dart';

mixin ArticleCommentMixin on GetxController {
  /// 由主 Controller 提供的依赖
  ArticleService get articleService;
  RxList<Article> get articles;
  String? get currentUserId;

  // ============================================================
  // 评论状态
  // ============================================================

  /// 当前文章的评论列表（树形根节点）
  final RxList<ArticleComment> currentComments = <ArticleComment>[].obs;

  /// 当前文章的评论总数（含回复）
  final RxInt totalCommentsCount = 0.obs;

  /// 评论是否正在加载
  final RxBool isCommentsLoading = false.obs;

  /// 当前选中的评论线程（用于楼中楼回复场景）
  final Rxn<ArticleComment> selectedThread = Rxn<ArticleComment>();

  // ============================================================
  // 评论查询
  // ============================================================

  /// 获取指定文章的评论列表，构建树形结构
  ///
  /// 流程：
  /// 1. 通过 Service 获取原始评论数据
  /// 2. 查询当前用户的点赞状态
  /// 3. 注入 replyToUserName（被回复者昵称）
  /// 4. 构建评论树（根评论 + 回复）
  Future<void> fetchComments(String articleId) async {
    try {
      isCommentsLoading.value = true;

      // 1. 获取原始评论数据（Service 内部有 fallback 机制）
      final data = await articleService.fetchComments(articleId);

      // 2. 查询当前用户的评论点赞状态
      final userId = currentUserId;
      Set<String> myLikedCommentIds = {};

      if (userId != null && data.isNotEmpty) {
        final commentIds = data.map((e) => e['id'] as String).toList();
        try {
          myLikedCommentIds = await articleService.fetchMyLikedCommentIds(
            userId,
            commentIds,
          );
        } catch (e) {
          // 点赞状态查询失败不影响评论展示
          print('[评论] 查询点赞状态失败: $e');
        }
      }

      // 3. 构建评论 ID → 原始数据 的映射（用于查找父评论的用户名）
      final Map<String, dynamic> commentIdToDataMap = {
        for (var item in data) item['id'] as String: item,
      };

      // 4. 将原始数据转为 ArticleComment 对象，注入额外字段
      final allComments = data.map((e) {
        final map = Map<String, dynamic>.from(e);

        // 注入「被回复者昵称」
        final parentId = map['parent_id'];
        if (parentId != null) {
          final parentData = commentIdToDataMap[parentId];
          if (parentData != null) {
            final profile = parentData['profiles'];
            if (profile != null) {
              map['reply_to_username'] = profile['username'];
            }
          }
        }

        // 注入当前用户的点赞状态
        map['is_liked'] = myLikedCommentIds.contains(map['id']);

        return ArticleComment.fromMap(map);
      }).toList();

      // 5. 构建评论树
      final Map<String, ArticleComment> commentMap = {
        for (var c in allComments) c.id: c,
      };

      final List<ArticleComment> rootComments = [];
      for (var c in allComments) {
        if (c.parentId == null) {
          // 顶层评论
          rootComments.add(c);
        } else {
          // 回复评论 — 挂在父评论下
          final parent = commentMap[c.parentId];
          if (parent != null) {
            parent.replies.add(c);
          } else {
            // 父评论不存在时作为顶层评论展示，避免丢失
            rootComments.add(c);
          }
        }
      }

      // 6. 按时间倒序排列根评论
      rootComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      currentComments.assignAll(rootComments);
      totalCommentsCount.value = allComments.length;

      // 7. 如果当前有选中的评论线程，用新数据刷新它
      if (selectedThread.value != null) {
        final updatedThread = rootComments.firstWhereOrNull(
          (c) => c.id == selectedThread.value!.id,
        );
        if (updatedThread != null) {
          selectedThread.value = updatedThread;
        }
      }
    } catch (e) {
      print('[评论] 加载评论失败: $e');
    } finally {
      isCommentsLoading.value = false;
    }
  }

  // ============================================================
  // 发布评论
  // ============================================================

  /// 发布文章评论（支持顶层评论和楼中楼回复）
  ///
  /// [parentId] 不为 null 时为楼中楼回复
  /// 发布成功后自动刷新评论列表和文章评论计数
  Future<bool> addComment(
    String articleId,
    String content, {
    String? parentId,
  }) async {
    // 权限检查
    if (!await Get.find<ProfileController>().checkActionAllowed('发布评论')) {
      return false;
    }

    // 安全检查（内容审核 + 频率限制）
    if (!Get.find<SafetyService>().canPost(
      content,
      'add_comment',
      cooldownSeconds: 10,
    )) {
      return false;
    }

    final userId = currentUserId;
    if (userId == null) {
      Get.snackbar('错误', '请先登录');
      return false;
    }

    try {
      // 发布评论
      await articleService.postComment(
        articleId: articleId,
        userId: userId,
        content: content,
        parentId: parentId,
      );

      // 刷新评论列表
      await fetchComments(articleId);

      // 更新文章评论计数（本地缓存）
      final articleIndex = articles.indexWhere((a) => a.id == articleId);
      String? articleAuthorId;

      if (articleIndex != -1) {
        articles[articleIndex].commentsCount++;
        articles.refresh();
        articleAuthorId = articles[articleIndex].userId;
      } else {
        // 文章不在本地缓存（如深链接场景），降级查询作者 ID
        articleAuthorId = await articleService.fetchArticleAuthorId(articleId);
      }

      // 发送通知给文章作者
      if (articleAuthorId != null) {
        await articleService.createNotification(
          targetUserId: articleAuthorId,
          actorId: userId,
          type: 'comment_article',
          resourceId: articleId,
          content: content,
        );
      }

      Get.snackbar(
        '成功',
        '评论已发布',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      // 检查成就徽章
      Get.put(BadgeService()).checkCommentMilestones();

      return true;
    } catch (e) {
      print('[评论] 发布评论失败: $e');
      Get.snackbar('错误', '评论发布失败: $e',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // ============================================================
  // 评论点赞
  // ============================================================

  /// 切换评论点赞状态（乐观更新 + 失败回滚）
  Future<void> toggleCommentLike(ArticleComment comment) async {
    // 权限检查
    if (!await Get.find<ProfileController>().checkActionAllowed('点赞评论')) {
      return;
    }

    final userId = currentUserId;
    if (userId == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    // 保存原始状态
    final wasLiked = comment.isLiked;

    // 乐观更新 UI
    comment.isLiked = !wasLiked;
    comment.likesCount += wasLiked ? -1 : 1;
    currentComments.refresh();
    if (selectedThread.value != null) selectedThread.refresh();

    try {
      if (wasLiked) {
        await articleService.unlikeComment(userId, comment.id);
      } else {
        await articleService.likeComment(userId, comment.id);

        // 通知评论作者
        await articleService.createNotification(
          targetUserId: comment.userId,
          actorId: userId,
          type: 'like_comment',
          resourceId: comment.id,
          content: comment.content,
        );
      }
    } catch (e) {
      // 回滚 UI 状态
      comment.isLiked = wasLiked;
      comment.likesCount += wasLiked ? 1 : -1;
      currentComments.refresh();
      if (selectedThread.value != null) selectedThread.refresh();
      Get.snackbar('服务器错误', '评论点赞失败: 请检查网络或联系管理员 ($e)',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isCommentsLoading.value = false;
    }
  }
}
