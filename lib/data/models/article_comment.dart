class ArticleComment {
  final String id;
  final String articleId;
  final String userId;
  final String content;
  final String? parentId;
  final DateTime createdAt;

  // User info (joined)
  final String? userAvatar;
  final String? userName;
  final String? replyToUserName;

  // Likes
  int likesCount;
  bool isLiked;

  // For UI
  List<ArticleComment> replies;

  ArticleComment({
    required this.id,
    required this.articleId,
    required this.userId,
    required this.content,
    this.parentId,
    required this.createdAt,
    this.userAvatar,
    this.userName,
    this.replyToUserName,
    this.likesCount = 0,
    this.isLiked = false,
    this.replies = const [],
  });

  factory ArticleComment.fromMap(Map<String, dynamic> map) {
    var profile = map['profiles']; // joined data

    // Parse likes count if available from a join or unexpected source,
    // but usually we inject it or map it separately.
    // For now, check if 'likes' is a list (Supabase count) or direct field.
    int likes = 0;
    if (map['likes_count'] != null) {
      likes = map['likes_count'] is int
          ? map['likes_count']
          : int.tryParse(map['likes_count'].toString()) ?? 0;
    } else if (map['likes'] != null && map['likes'] is List) {
      // If we select 'likes:article_comment_likes(count)', Supabase returns a list with one object {count: N}
      final list = map['likes'] as List;
      if (list.isNotEmpty && list.first['count'] != null) {
        likes = list.first['count'] as int;
      }
    }

    // Parse isLiked
    bool liked = false;
    if (map['is_liked'] != null) {
      liked = map['is_liked'] as bool;
    } else if (map['my_likes'] != null && map['my_likes'] is List) {
      // If we select 'my_likes:article_comment_likes(...)' filter by me
      final list = map['my_likes'] as List;
      liked = list.isNotEmpty;
    }

    return ArticleComment(
      id: map['id'],
      articleId: map['article_id'],
      userId: map['user_id'],
      content: map['content'],
      parentId: map['parent_id'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      userAvatar: profile != null ? profile['avatar_url'] : null,
      userName: profile != null ? profile['username'] : null,
      replyToUserName: map['reply_to_username'],
      likesCount: likes,
      isLiked: liked,
      replies: [],
    );
  }
  // Recursive reply count
  int get totalRepliesCount {
    int count = replies.length;
    for (var reply in replies) {
      count += reply.totalRepliesCount;
    }
    return count;
  }
}
