class Article {
  final String id;
  final String userId;
  final String title;
  final String? summary;
  final String? coverUrl;
  final dynamic content; // JSON (List<dynamic> or Map)
  final DateTime createdAt;
  final bool isPublished;

  // Optional: User info for display (fetched via join or separate query)
  final String? authorName;
  final String? authorAvatar;

  Article({
    required this.id,
    required this.userId,
    required this.title,
    this.summary,
    this.coverUrl,
    this.content,
    required this.createdAt,
    this.isPublished = true,
    this.authorName,
    this.authorAvatar,
    this.likesCount = 0,
    this.collectionsCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isCollected = false,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String?,
      coverUrl: map['cover_url'] as String?,
      content: map['content'], // Keep as dynamic (JSON)
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      isPublished: map['is_published'] as bool? ?? true,
      // Handle joined profile data if available
      authorName: map['profiles']?['username'] as String?,
      authorAvatar: map['profiles']?['avatar_url'] as String?,

      // Social Interactions (Aggregated counts or flags)
      // Note: 'likes' and 'collections' might be Lists if fetched via select(..., likes:article_likes(count))
      likesCount: _parseCount(map['likes']),
      collectionsCount: _parseCount(map['collections']),
      commentsCount: _parseCount(map['comments']),
      // For 'isLiked', we might fetch it separately or via a smart join.
      // For MVP simple implementation, we might fetch user-specific status in a separate list or assume data is massaged.
      // But commonly: select(..., my_likes:article_likes!inner(user_id)) if filtered by user.
      // Let's assume the controller will enrich this or we rely on a separate 'is_liked' field if using a view.
      // For now, let's keep it simple: Controller handles 'isLiked' logic or we pass it in.
      // Wait, let's add mutable fields for UI state management first.
    );
  }

  // Helper to parse count from Supabase response format usually [{count: 5}] or similar
  static int _parseCount(dynamic data) {
    if (data == null) return 0;
    if (data is List) {
      if (data.isNotEmpty && data[0] is Map && data[0]['count'] != null) {
        return data[0]['count'] as int;
      }
      // If just a list of IDs, return length
      return data.length;
    }
    return 0;
  }

  // Social Stats (Mutable for UI updates)
  int likesCount;
  int collectionsCount;
  int commentsCount;
  bool isLiked;
  bool isCollected; // 'Bookmarked'

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'summary': summary,
      'cover_url': coverUrl,
      'content': content,
      'is_published': isPublished,
      // 'created_at': createdAt.toIso8601String(), // Usually handled by DB default
    };
  }
}
