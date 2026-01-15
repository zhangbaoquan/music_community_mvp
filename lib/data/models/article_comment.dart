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
    this.replies = const [],
  });

  factory ArticleComment.fromMap(Map<String, dynamic> map) {
    var profile = map['profiles']; // joined data
    return ArticleComment(
      id: map['id'],
      articleId: map['article_id'],
      userId: map['user_id'],
      content: map['content'],
      parentId: map['parent_id'],
      createdAt: DateTime.parse(map['created_at']).toLocal(),
      userAvatar: profile != null ? profile['avatar_url'] : null,
      userName: profile != null ? profile['username'] : null,
      replies: [],
    );
  }
}
