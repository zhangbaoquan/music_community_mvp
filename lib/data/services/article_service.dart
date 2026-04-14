/// 文章数据服务层 — 封装所有文章相关的 Supabase 调用
///
/// 本服务负责：
/// - 文章 CRUD（查询、发布、更新、删除）
/// - 文章互动（点赞、收藏）
/// - 文章评论（查询、发布、点赞）
/// - 文件上传（封面图、文章内图片）
/// - 通知创建（互动触发的通知）
///
/// 设计原则：
/// - Controller 和 View 禁止直接调用 Supabase
/// - 所有 Supabase 调用必须有 try-catch
/// - 使用 [LogService] 记录错误
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/article.dart';
import '../models/article_comment.dart';

class ArticleService {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // 文章查询
  // ============================================================

  /// 查询字段模板 — 统一的 select 字段，避免各处硬编码
  static const String _articleSelectFields =
      '*, bgm_song_id, profiles(username, avatar_url), songs(title), '
      'likes:article_likes(count), collections:article_collections(count), '
      'comments:article_comments(count)';

  /// 获取所有已发布的文章列表（按创建时间倒序）
  ///
  /// 返回原始数据列表，由 Controller 负责转换为 Article 对象
  Future<List<Article>> fetchArticles() async {
    final response = await _supabase
        .from('articles')
        .select(_articleSelectFields)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((e) => Article.fromMap(e)).toList();
  }

  /// 获取单篇文章详情（用于深链接/详情页）
  Future<Article> fetchArticleDetail(String articleId) async {
    final response = await _supabase
        .from('articles')
        .select(_articleSelectFields)
        .eq('id', articleId)
        .single();

    return Article.fromMap(response);
  }

  /// 获取指定用户的文章列表（用于个人主页）
  Future<List<Article>> fetchUserArticles(String userId) async {
    final response = await _supabase
        .from('articles')
        .select(_articleSelectFields)
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data.map((e) => Article.fromMap(e)).toList();
  }

  // ============================================================
  // 用户互动状态查询（批量）
  // ============================================================

  /// 批量查询当前用户对文章的点赞状态
  ///
  /// 返回已点赞的文章 ID 集合
  Future<Set<String>> fetchMyLikedArticleIds(
    String userId,
    List<String> articleIds,
  ) async {
    if (articleIds.isEmpty) return {};

    final response = await _supabase
        .from('article_likes')
        .select('article_id')
        .eq('user_id', userId)
        .inFilter('article_id', articleIds);

    return (response as List).map((e) => e['article_id'] as String).toSet();
  }

  /// 批量查询当前用户对文章的收藏状态
  ///
  /// 返回已收藏的文章 ID 集合
  Future<Set<String>> fetchMyCollectedArticleIds(
    String userId,
    List<String> articleIds,
  ) async {
    if (articleIds.isEmpty) return {};

    final response = await _supabase
        .from('article_collections')
        .select('article_id')
        .eq('user_id', userId)
        .inFilter('article_id', articleIds);

    return (response as List).map((e) => e['article_id'] as String).toSet();
  }

  /// 查询单篇文章的点赞状态
  Future<bool> isArticleLiked(String userId, String articleId) async {
    final result = await _supabase
        .from('article_likes')
        .select('article_id')
        .eq('user_id', userId)
        .eq('article_id', articleId)
        .maybeSingle();
    return result != null;
  }

  /// 查询单篇文章的收藏状态
  Future<bool> isArticleCollected(String userId, String articleId) async {
    final result = await _supabase
        .from('article_collections')
        .select('article_id')
        .eq('user_id', userId)
        .eq('article_id', articleId)
        .maybeSingle();
    return result != null;
  }

  // ============================================================
  // 文章互动操作
  // ============================================================

  /// 添加文章点赞
  Future<void> likeArticle(String userId, String articleId) async {
    await _supabase.from('article_likes').insert({
      'user_id': userId,
      'article_id': articleId,
    });
  }

  /// 取消文章点赞
  Future<void> unlikeArticle(String userId, String articleId) async {
    await _supabase.from('article_likes').delete().match({
      'user_id': userId,
      'article_id': articleId,
    });
  }

  /// 添加文章收藏
  Future<void> collectArticle(String userId, String articleId) async {
    await _supabase.from('article_collections').insert({
      'user_id': userId,
      'article_id': articleId,
    });
  }

  /// 取消文章收藏
  Future<void> uncollectArticle(String userId, String articleId) async {
    await _supabase.from('article_collections').delete().match({
      'user_id': userId,
      'article_id': articleId,
    });
  }

  // ============================================================
  // 评论相关
  // ============================================================

  /// 获取文章评论列表（带作者信息和点赞数）
  ///
  /// 内部有 fallback 机制：先尝试 join profiles，失败后手动查询
  Future<List<Map<String, dynamic>>> fetchComments(String articleId) async {
    try {
      // 优先尝试 join 查询（一次性获取评论 + 用户信息 + 点赞数）
      final response = await _supabase
          .from('article_comments')
          .select(
            '*, profiles(username, avatar_url), likes:article_comment_likes(count)',
          )
          .eq('article_id', articleId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // 降级方案：分两步查询
      final response = await _supabase
          .from('article_comments')
          .select('*, likes:article_comment_likes(count)')
          .eq('article_id', articleId)
          .order('created_at', ascending: true);

      final data = List<Map<String, dynamic>>.from(
        (response as List).map((e) => Map<String, dynamic>.from(e)),
      );

      // 手动查询用户信息并合并
      final userIds =
          data.map((e) => e['user_id'] as String).toSet().toList();
      if (userIds.isNotEmpty) {
        final profilesResponse = await _supabase
            .from('profiles')
            .select('id, username, avatar_url')
            .filter('id', 'in', userIds);

        final profilesMap = {for (var p in profilesResponse) p['id']: p};
        for (var i = 0; i < data.length; i++) {
          final pid = data[i]['user_id'];
          if (profilesMap.containsKey(pid)) {
            data[i]['profiles'] = profilesMap[pid];
          }
        }
      }
      return data;
    }
  }

  /// 批量查询当前用户对评论的点赞状态
  ///
  /// 返回已点赞的评论 ID 集合
  Future<Set<String>> fetchMyLikedCommentIds(
    String userId,
    List<String> commentIds,
  ) async {
    if (commentIds.isEmpty) return {};

    final response = await _supabase
        .from('article_comment_likes')
        .select('comment_id')
        .eq('user_id', userId)
        .inFilter('comment_id', commentIds);

    return (response as List).map((e) => e['comment_id'] as String).toSet();
  }

  /// 发布评论
  Future<void> postComment({
    required String articleId,
    required String userId,
    required String content,
    String? parentId,
  }) async {
    await _supabase.from('article_comments').insert({
      'article_id': articleId,
      'user_id': userId,
      'content': content,
      'parent_id': parentId,
    });
  }

  /// 添加评论点赞
  Future<void> likeComment(String userId, String commentId) async {
    await _supabase.from('article_comment_likes').insert({
      'user_id': userId,
      'comment_id': commentId,
    });
  }

  /// 取消评论点赞
  Future<void> unlikeComment(String userId, String commentId) async {
    await _supabase.from('article_comment_likes').delete().match({
      'user_id': userId,
      'comment_id': commentId,
    });
  }

  // ============================================================
  // 通知
  // ============================================================

  /// 创建互动通知（点赞、评论等触发）
  ///
  /// [targetUserId] 接收通知的用户
  /// [actorId] 触发通知的用户
  /// [type] 通知类型：like_article / comment_article / like_comment
  /// [resourceId] 关联资源 ID（文章或评论）
  /// [content] 通知内容摘要（可选）
  Future<void> createNotification({
    required String targetUserId,
    required String actorId,
    required String type,
    required String resourceId,
    String? content,
  }) async {
    // 不给自己发通知
    if (targetUserId == actorId) return;

    await _supabase.from('notifications').insert({
      'user_id': targetUserId,
      'actor_id': actorId,
      'type': type,
      'resource_id': resourceId,
      if (content != null) 'content': content,
    });
  }

  /// 查询文章作者 ID（用于通知场景，文章不在本地缓存时的降级查询）
  Future<String?> fetchArticleAuthorId(String articleId) async {
    try {
      final res = await _supabase
          .from('articles')
          .select('user_id')
          .eq('id', articleId)
          .single();
      return res['user_id'] as String;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // 文章 CRUD
  // ============================================================

  /// 删除文章
  Future<void> deleteArticle(String articleId) async {
    await _supabase.from('articles').delete().eq('id', articleId);
  }

  /// 更新文章
  Future<void> updateArticle(
    String articleId,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('articles').update(updates).eq('id', articleId);
  }

  /// 插入新文章
  Future<void> insertArticle(Map<String, dynamic> data) async {
    await _supabase.from('articles').insert(data);
  }

  // ============================================================
  // 文件上传
  // ============================================================

  /// 上传文章封面图
  ///
  /// 返回上传后的公开访问 URL
  /// [userId] 用于构建文件路径前缀，防止文件名冲突
  /// [fileBytes] 文件二进制数据
  /// [fileExtension] 文件扩展名（如 jpg, png）
  Future<String> uploadCoverImage({
    required String userId,
    required Uint8List fileBytes,
    required String fileExtension,
  }) async {
    final fileName =
        '$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    await _supabase.storage.from('article_covers').uploadBinary(
      fileName,
      fileBytes,
      fileOptions: const FileOptions(upsert: true),
    );

    return _supabase.storage.from('article_covers').getPublicUrl(fileName);
  }

  /// 上传文章内嵌图片
  ///
  /// 返回上传后的公开访问 URL
  /// [fileName] 完整文件名（含路径前缀）
  /// [fileBytes] 文件二进制数据
  Future<String> uploadArticleImage({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final path = 'article_images/$fileName';

    await _supabase.storage.from('articles').uploadBinary(
      path,
      fileBytes,
      fileOptions: const FileOptions(upsert: false),
    );

    return _supabase.storage.from('articles').getPublicUrl(path);
  }

  // ============================================================
  // 歌曲查询（为文章详情页的 BGM 播放服务）
  // ============================================================

  /// 根据 ID 获取歌曲详情
  ///
  /// 用于文章详情页自动播放 BGM 场景
  Future<Map<String, dynamic>> fetchSongById(String songId) async {
    return await _supabase
        .from('songs')
        .select()
        .eq('id', songId)
        .single()
        .timeout(
          const Duration(seconds: 8),
          onTimeout: () => throw Exception('获取歌曲超时'),
        );
  }
}
