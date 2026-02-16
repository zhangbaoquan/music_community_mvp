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

  // BGM Info
  final String? bgmSongId;
  final String? bgmTitle;

  // Metadata
  final String type; // 'original' or 'repost'
  final List<String> tags;

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
    this.bgmSongId,
    this.bgmTitle,
    this.likesCount = 0,
    this.collectionsCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isCollected = false,
    this.type = 'original',
    this.tags = const [],
  });

  factory Article.empty() {
    return Article(id: '', userId: '', title: '', createdAt: DateTime.now());
  }

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

      bgmSongId: map['bgm_song_id'] as String?,
      // Note: If we join songs(title), it might be inside 'songs' object
      bgmTitle: map['songs'] != null ? map['songs']['title'] as String? : null,

      // Metadata
      type: map['type'] as String? ?? 'original',
      tags:
          (map['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],

      // Social Interactions (Aggregated counts or flags)
      likesCount: _parseCount(map['likes']),
      collectionsCount: _parseCount(map['collections']),
      commentsCount: _parseCount(map['comments']),
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
      'bgm_song_id': bgmSongId,
      'type': type,
      'tags': tags,
      // 'created_at': createdAt.toIso8601String(), // Usually handled by DB default
    };
  }

  Article copyWith({
    String? id,
    String? userId,
    String? title,
    String? summary,
    String? coverUrl,
    dynamic content,
    DateTime? createdAt,
    bool? isPublished,
    String? authorName,
    String? authorAvatar,
    String? bgmSongId,
    String? bgmTitle,
    int? likesCount,
    int? collectionsCount,
    int? commentsCount,
    bool? isLiked,
    bool? isCollected,
    String? type,
    List<String>? tags,
  }) {
    return Article(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      coverUrl: coverUrl ?? this.coverUrl,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPublished: isPublished ?? this.isPublished,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      bgmSongId: bgmSongId ?? this.bgmSongId,
      bgmTitle: bgmTitle ?? this.bgmTitle,
      likesCount: likesCount ?? this.likesCount,
      collectionsCount: collectionsCount ?? this.collectionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isCollected: isCollected ?? this.isCollected,
      type: type ?? this.type,
      tags: tags ?? this.tags,
    );
  }
}
