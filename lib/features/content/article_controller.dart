import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/article.dart';
import 'package:music_community_mvp/data/models/article_comment.dart';

import '../gamification/badge_service.dart';
import '../profile/profile_controller.dart';
import '../safety/safety_service.dart';

class ArticleController extends GetxController {
  final _supabase = Supabase.instance.client;

  // Observables
  final isLoading = false.obs;
  final isUploading = false.obs;
  final articles = <Article>[].obs;
  final userArticles = <Article>[].obs; // For "My Articles" section

  @override
  void onInit() {
    super.onInit();
    fetchArticles();

    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        clearArticlesState();
      } else if (data.event == AuthChangeEvent.signedIn) {
        // Refetch on new login to refresh like/collection bindings
        fetchArticles();
      }
    });
  }

  void clearArticlesState() {
    userArticles.clear();
    // Do we clear public articles too? Probably good so we don't leak "Liked" status
    // of the previous user into the public list until refetched.
    articles.clear();
  }

  /// Fetch all published articles with author profile info & social stats
  Future<void> fetchArticles() async {
    try {
      isLoading.value = true;
      final userId = _supabase.auth.currentUser?.id;

      // 1. Fetch Articles with Counts
      final response = await _supabase
          .from('articles')
          .select(
            '*, bgm_song_id, profiles(username, avatar_url), songs(title), likes:article_likes(count), collections:article_collections(count), comments:article_comments(count)',
          )
          .eq('is_published', true)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      final loadedArticles = data.map((e) => Article.fromMap(e)).toList();

      // 2. Fetch User's Interaction Status (if logged in)
      if (userId != null) {
        // Prepare list of article IDs to query
        final articleIds = loadedArticles.map((a) => a.id).toList();

        if (articleIds.isNotEmpty) {
          // Check likes
          final myLikes = await _supabase
              .from('article_likes')
              .select('article_id')
              .eq('user_id', userId)
              .inFilter('article_id', articleIds);

          final likedIds = (myLikes as List)
              .map((e) => e['article_id'])
              .toSet();

          // Check collections
          final myCollections = await _supabase
              .from('article_collections')
              .select('article_id')
              .eq('user_id', userId)
              .inFilter('article_id', articleIds);

          final collectedIds = (myCollections as List)
              .map((e) => e['article_id'])
              .toSet();

          // Merge status
          for (var article in loadedArticles) {
            article.isLiked = likedIds.contains(article.id);
            article.isCollected = collectedIds.contains(article.id);
          }
        }
      }

      articles.value = loadedArticles;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load articles: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch Single Article Details (for Deep Linking)
  Future<Article?> fetchArticleDetails(String id) async {
    try {
      isLoading.value = true;
      final userId = _supabase.auth.currentUser?.id;

      final response = await _supabase
          .from('articles')
          .select(
            '*, bgm_song_id, profiles(username, avatar_url), songs(title), likes:article_likes(count), collections:article_collections(count), comments:article_comments(count)',
          )
          .eq('id', id)
          .single();

      final article = Article.fromMap(response);

      // Fetch User Status
      if (userId != null) {
        // Check like
        final myLike = await _supabase
            .from('article_likes')
            .select('article_id')
            .eq('user_id', userId)
            .eq('article_id', id)
            .maybeSingle();
        article.isLiked = myLike != null;

        // Check collection
        final myCol = await _supabase
            .from('article_collections')
            .select('article_id')
            .eq('user_id', userId)
            .eq('article_id', id)
            .maybeSingle();
        article.isCollected = myCol != null;
      }
      return article;
    } catch (e) {
      print('Error fetching article details: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(Article article) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('点赞文章')) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    final originalIsLiked = article.isLiked;
    final originalCount = article.likesCount;

    // Optimistic Update
    article.isLiked = !originalIsLiked;
    article.likesCount += (originalIsLiked ? -1 : 1).clamp(-999999, 999999);
    articles.refresh();

    try {
      if (originalIsLiked) {
        // Unlike
        await _supabase.from('article_likes').delete().match({
          'user_id': userId,
          'article_id': article.id,
        });
      } else {
        // Like
        await _supabase.from('article_likes').insert({
          'user_id': userId,
          'article_id': article.id,
        });

        // Notification: Like Article
        if (article.userId != userId) {
          await _supabase.from('notifications').insert({
            'user_id': article.userId,
            'actor_id': userId,
            'type': 'like_article',
            'resource_id': article.id,
          });
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Revert if UI update was premature
      article.isLiked = originalIsLiked;
      article.likesCount = originalCount;
      articles.refresh();
      Get.snackbar(
        '服务器错误',
        '点赞失败: 请检查网络或联系管理员 ($e)',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Toggle Collection
  Future<void> toggleCollection(Article article) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('收藏文章')) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    final originalIsCollected = article.isCollected;
    final originalCount = article.collectionsCount;

    // Optimistic Update
    article.isCollected = !originalIsCollected;
    article.collectionsCount += (originalIsCollected ? -1 : 1).clamp(
      -999999,
      999999,
    );
    articles.refresh();

    try {
      if (originalIsCollected) {
        // Remove Collection
        await _supabase.from('article_collections').delete().match({
          'user_id': userId,
          'article_id': article.id,
        });
      } else {
        // Add Collection
        await _supabase.from('article_collections').insert({
          'user_id': userId,
          'article_id': article.id,
        });
      }

      // Sync with ProfileController if it's alive
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().fetchCollectedArticles();
      }
    } catch (e) {
      print('Error toggling collection: $e');
      // Revert if UI update was premature
      article.isCollected = originalIsCollected;
      article.collectionsCount = originalCount;
      articles.refresh();
      Get.snackbar(
        '服务器错误',
        '收藏失败: 请检查网络或联系管理员 ($e)',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // -------------------------
  // Comments Logic
  // -------------------------

  RxList<ArticleComment> currentComments = <ArticleComment>[].obs;
  RxInt totalCommentsCount = 0.obs;
  RxBool isCommentsLoading = false.obs;
  Rxn<ArticleComment> selectedThread = Rxn<ArticleComment>();

  Future<void> fetchComments(String articleId) async {
    try {
      isCommentsLoading.value = true;
      List<dynamic> data;
      try {
        print('[DEBUG fetchComments] Trying primary join...');
        // Try optimized fetch with join
        final response = await _supabase
            .from('article_comments')
            .select(
              '*, profiles(username, avatar_url), likes:article_comment_likes(count)',
            )
            .eq('article_id', articleId)
            .order('created_at', ascending: true);
        data = response as List<dynamic>;
        print(
          '[DEBUG fetchComments] Primary join success, loaded ${data.length} comments.',
        );
      } catch (e) {
        // Fallback: Fetch comments then fetch profiles manually
        print(
          '[DEBUG fetchComments] Primary join failed ($e). using fallback...',
        );
        final response = await _supabase
            .from('article_comments')
            .select('*, likes:article_comment_likes(count)')
            .eq('article_id', articleId)
            .order('created_at', ascending: true);
        data = response as List<dynamic>;
        print('[DEBUG fetchComments] Fallback loaded ${data.length} comments.');

        // Fetch user profiles
        final userIds = data
            .map((e) => e['user_id'] as String)
            .toSet()
            .toList();
        if (userIds.isNotEmpty) {
          final profilesResponse = await _supabase
              .from('profiles')
              .select('id, username, avatar_url')
              .filter('id', 'in', userIds);
          final profilesMap = {for (var p in profilesResponse) p['id']: p};
          for (var i = 0; i < data.length; i++) {
            final pid = data[i]['user_id'];
            if (profilesMap.containsKey(pid)) {
              // Copy to become mutable if not already
              final map = Map<String, dynamic>.from(data[i]);
              map['profiles'] = profilesMap[pid];
              data[i] = map;
            }
          }
        }
      }

      // ---------------------------------------------------------
      // Common Logic: Format Comments (Flatten/Tree)
      // ---------------------------------------------------------

      // Fetch My Likes (isLiked status)
      final user = _supabase.auth.currentUser;
      Set<String> myLikedCommentIds = {};

      print('[DEBUG fetchComments] Authenticated user: ${user?.id}');

      if (user != null && data.isNotEmpty) {
        final commentIds = data.map((e) => e['id'] as String).toList();
        try {
          final myLikesResponse = await _supabase
              .from('article_comment_likes')
              .select('comment_id')
              .eq('user_id', user.id)
              .inFilter('comment_id', commentIds);

          for (var like in myLikesResponse) {
            myLikedCommentIds.add(like['comment_id'] as String);
          }
          print(
            '[DEBUG fetchComments] User has liked ${myLikedCommentIds.length} comments in this list: $myLikedCommentIds',
          );
        } catch (e) {
          print('[DEBUG fetchComments] Error checking my likes: $e');
        }
      }

      // 1. Create a lookup map for raw data to find parent profiles easily
      final Map<String, dynamic> commentIdToDataMap = {
        for (var item in data) item['id'] as String: item,
      };

      // 2. Map raw data to ArticleComment objects, injecting 'replyToUserName'
      final allComments = data.map((e) {
        final map = Map<String, dynamic>.from(e);
        String? replyToName;
        final parentId = map['parent_id'];
        if (parentId != null) {
          final parentData = commentIdToDataMap[parentId];
          if (parentData != null) {
            // profiles might be joined
            final profile = parentData['profiles'];
            if (profile != null) {
              replyToName = profile['username'];
            }
          }
        }

        // Inject into map for fromMap to use
        map['reply_to_username'] = replyToName;

        // Inject is_liked
        map['is_liked'] = myLikedCommentIds.contains(map['id']);

        return ArticleComment.fromMap(map);
      }).toList();

      // 3. Create a lookup map for ArticleComment objects to build the tree
      final Map<String, ArticleComment> commentMap = {
        for (var c in allComments) c.id: c,
      };

      // 4. Build the Comment Tree (Root -> Replies)
      final List<ArticleComment> rootComments = [];

      for (var c in allComments) {
        if (c.parentId == null) {
          rootComments.add(c);
        } else {
          final parent = commentMap[c.parentId];
          if (parent != null) {
            parent.replies.add(c);
          } else {
            // Fallback: if parent not found, treat as root? Or ignore?
            // Treating as root ensures it's seen.
            rootComments.add(c);
          }
        }
      }

      rootComments.sort((a, b) {
        // createdAt is non-nullable in ArticleComment
        return b.createdAt.compareTo(a.createdAt);
      });

      currentComments.assignAll(rootComments);
      totalCommentsCount.value = allComments.length;

      // If we have a selected thread, we need to update it with the new object
      // so that new replies are visible in the UI.
      if (selectedThread.value != null) {
        final updatedThread = rootComments.firstWhereOrNull(
          (c) => c.id == selectedThread.value!.id,
        );
        if (updatedThread != null) {
          selectedThread.value = updatedThread;
        }
      }
    } catch (e) {
      print('[DEBUG fetchComments] Critical error catching fetchComments: $e');
    } finally {
      isCommentsLoading.value = false;
    }
  }

  Future<bool> addComment(
    String articleId,
    String content, {
    String? parentId,
  }) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('发布评论')) {
      return false;
    }

    // Safety Check
    if (!Get.find<SafetyService>().canPost(
      content,
      'add_comment',
      cooldownSeconds: 10,
    )) {
      return false;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) {
      Get.snackbar('错误', '请先登录');
      return false;
    }

    try {
      await _supabase.from('article_comments').insert({
        'article_id': articleId,
        'user_id': user.id,
        'content': content,
        'parent_id': parentId,
      });

      // Refresh comments and article count
      await fetchComments(articleId);

      // Update article comment count locally
      final articleIndex = articles.indexWhere((a) => a.id == articleId);
      if (articleIndex != -1) {
        articles[articleIndex].commentsCount++;
        articles.refresh();

        // Notification: Comment on Article
        final articleAuthorId = articles[articleIndex].userId;
        if (articleAuthorId != user.id) {
          await _supabase.from('notifications').insert({
            'user_id': articleAuthorId,
            'actor_id': user.id,
            'type': 'comment_article',
            'resource_id': articleId,
            'content': content,
          });
        }
      } else {
        // Fallback if article not in local list (e.g. opened deep link)
        try {
          final articleRes = await _supabase
              .from('articles')
              .select('user_id')
              .eq('id', articleId)
              .single();
          final authorId = articleRes['user_id'] as String;
          if (authorId != user.id) {
            await _supabase.from('notifications').insert({
              'user_id': authorId,
              'actor_id': user.id,
              'type': 'comment_article',
              'resource_id': articleId,
              'content': content,
            });
          }
        } catch (_) {}
      }

      Get.snackbar(
        '成功',
        '评论已发布',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );

      // Check Milestones (Phase 14)
      Get.put(BadgeService()).checkCommentMilestones();

      return true;
    } catch (e) {
      print('Error posting comment: $e');
      Get.snackbar('错误', '评论发布失败: $e', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // Toggle Comment Like
  Future<void> toggleCommentLike(ArticleComment comment) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('点赞评论')) return;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      Get.snackbar('提示', '请先登录');
      return;
    }

    final isLiked = comment.isLiked;
    // Optimistic Update
    comment.isLiked = !isLiked;
    comment.likesCount += (isLiked ? -1 : 1);
    currentComments.refresh(); // Trigger Obx
    if (selectedThread.value != null) {
      selectedThread.refresh();
    }

    try {
      if (isLiked) {
        // Unlike
        await _supabase.from('article_comment_likes').delete().match({
          'user_id': user.id,
          'comment_id': comment.id,
        });
      } else {
        // Like
        await _supabase.from('article_comment_likes').insert({
          'user_id': user.id,
          'comment_id': comment.id,
        });

        // Notification: Like Comment
        if (comment.userId != user.id) {
          await _supabase.from('notifications').insert({
            'user_id': comment.userId,
            'actor_id': user.id,
            'type': 'like_comment',
            'resource_id': comment.id,
            'content': comment.content,
          });
        }
      }
    } catch (e) {
      // Revert
      comment.isLiked = isLiked;
      comment.likesCount += (isLiked ? 1 : -1);
      currentComments.refresh();
      if (selectedThread.value != null) selectedThread.refresh();
      print('Error toggling like: $e');
      Get.snackbar(
        '服务器错误',
        '评论点赞失败: 请检查网络或联系管理员 ($e)',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isCommentsLoading.value = false;
    }
  }

  /// Fetch Articles by User ID (for Profile)
  Future<void> fetchUserArticles(String userId) async {
    try {
      final response = await _supabase
          .from('articles')
          .select(
            '*, profiles(username, avatar_url), songs(title), likes:article_likes(count), collections:article_collections(count), comments:article_comments(count)',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      userArticles.value = data.map((e) => Article.fromMap(e)).toList();
    } catch (e) {
      print('Error fetching user articles: $e');
    }
  }

  /// Delete Article
  Future<bool> deleteArticle(String articleId) async {
    if (!await Get.find<ProfileController>().checkActionAllowed('删除文章')) {
      return false;
    }
    try {
      await _supabase.from('articles').delete().eq('id', articleId);
      articles.removeWhere((a) => a.id == articleId);
      userArticles.removeWhere((a) => a.id == articleId);
      return true;
    } catch (e) {
      print('Error deleting article: $e');
      return false;
    }
  }

  /// Update Article
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

    // Safety Check
    final safetyService = Get.find<SafetyService>();
    if (!safetyService.validateContent(title) ||
        !safetyService.validateContent(summary)) {
      return false;
    }

    try {
      isUploading.value = true;
      final updates = <String, dynamic>{
        'title': title,
        'summary': summary,
        'content': contentJson,
        'bgm_song_id': bgmSongId,
        'type': type,
        'tags': tags,
        'is_published': true, // Auto re-publish if it was hidden
      };

      if (coverFile != null) {
        final userId = _supabase.auth.currentUser!.id;
        final fileExt = coverFile.name.split('.').last;
        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await _supabase.storage
            .from('article_covers')
            .uploadBinary(
              fileName,
              coverFile.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = _supabase.storage
            .from('article_covers')
            .getPublicUrl(fileName);
        updates['cover_url'] = publicUrl;
      }

      await _supabase.from('articles').update(updates).eq('id', articleId);

      // Refresh list
      await fetchArticles();
      // Also refresh user articles if needed
      final user = _supabase.auth.currentUser;
      if (user != null) fetchUserArticles(user.id);

      return true;
    } catch (e) {
      print('Error updating article: $e');
      Get.snackbar('更新失败', '错误信息: $e', duration: const Duration(seconds: 5));
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  // -------------------------
  // Publish
  // -------------------------
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

    // Safety Check
    final safetyService = Get.find<SafetyService>();
    if (!safetyService.validateContent(title) ||
        !safetyService.validateContent(summary)) {
      return false;
    }
    // Rate Limit for Articles (60s)
    if (!safetyService.checkRateLimit('publish_article')) {
      return false;
    }

    try {
      isUploading.value = true;
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      String? coverUrl;

      if (coverFile != null) {
        final userId = user.id;
        final fileExt = coverFile.name.split('.').last;
        final fileName =
            '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await _supabase.storage
            .from('article_covers')
            .uploadBinary(
              fileName,
              coverFile.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        coverUrl = _supabase.storage
            .from('article_covers')
            .getPublicUrl(fileName);
      }

      final article = Article(
        id: '', // Generated by DB
        userId: user.id,
        title: title,
        summary: summary,
        coverUrl: coverUrl,
        content: contentJson,
        createdAt: DateTime.now(),
        bgmSongId: bgmSongId,
        type: type,
        tags: tags,
      );

      await _supabase.from('articles').insert(article.toMap()..remove('id'));

      // 3. Refresh list (fire and forget, or await if needed)
      fetchArticles();
      // Also refresh user articles for profile view
      fetchUserArticles(user.id);

      // Check Milestones (Phase 14)
      Get.put(BadgeService()).checkArticleMilestones();

      return true;
    } catch (e) {
      print('Publish Error: $e');
      Get.snackbar('发布失败', '错误信息: $e', duration: const Duration(seconds: 5));
      return false;
    } finally {
      isUploading.value = false;
    }
  }
}
