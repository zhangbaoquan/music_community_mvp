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
    );
  }

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
